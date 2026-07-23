import UIKit
import AVFoundation
import Photos

/// Camera capture with a scanning treatment: a framed reticle, animated sweep
/// line, and a strip of recent photos so the user can pick one instead.
final class WFCameraScanViewController: UIViewController {

    private let onCapture: (UIImage) -> Void
    private let onCancel: () -> Void

    // MARK: - Capture

    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "wf.camera.session")
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var isSessionConfigured = false

    // MARK: - UI

    private let previewContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let reticleView = WFUIScanReticleView(frame: .zero)

    private let hintLabel: UILabel = {
        let label = UILabel()
        label.text = "Line the dish up inside the frame"
        label.font = WFUIFont.body(13, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOpacity = 0.5
        label.layer.shadowRadius = 4
        label.layer.shadowOffset = .zero
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let shutterButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .white
        button.layer.cornerRadius = 34
        button.layer.borderWidth = 4
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.45).cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        button.layer.cornerRadius = 18
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let recentsLabel: UILabel = {
        let label = UILabel()
        label.text = "Recents"
        label.font = WFUIFont.body(12, weight: .bold)
        label.textColor = UIColor.white.withAlphaComponent(0.75)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var recentsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 62, height: 62)
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(WFUIRecentPhotoCell.self, forCellWithReuseIdentifier: WFUIRecentPhotoCell.reuseID)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    private var recentAssets: [PHAsset] = []
    private let imageManager = PHCachingImageManager()

    // MARK: - Init

    init(onCapture: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
        self.onCapture = onCapture
        self.onCancel = onCancel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        setupLayout()
        requestCameraAccess()
        loadRecentPhotos()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reticleView.startScanning()

        sessionQueue.async { [weak self] in
            guard let self, self.isSessionConfigured, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        reticleView.stopScanning()

        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = previewContainer.bounds
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    // MARK: - Setup

    private func setupLayout() {
        view.addSubview(previewContainer)
        view.addSubview(reticleView)
        view.addSubview(hintLabel)
        view.addSubview(closeButton)
        view.addSubview(shutterButton)
        view.addSubview(recentsLabel)
        view.addSubview(recentsCollectionView)

        reticleView.translatesAutoresizingMaskIntoConstraints = false
        reticleView.isUserInteractionEnabled = false

        closeButton.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        shutterButton.addTarget(self, action: #selector(handleShutter), for: .touchUpInside)

        NSLayoutConstraint.activate([
            previewContainer.topAnchor.constraint(equalTo: view.topAnchor),
            previewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36),

            reticleView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            reticleView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            reticleView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.78),
            reticleView.heightAnchor.constraint(equalTo: reticleView.widthAnchor),

            hintLabel.topAnchor.constraint(equalTo: reticleView.bottomAnchor, constant: 18),
            hintLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            hintLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            recentsCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            recentsCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            recentsCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            recentsCollectionView.heightAnchor.constraint(equalToConstant: 62),

            recentsLabel.bottomAnchor.constraint(equalTo: recentsCollectionView.topAnchor, constant: -8),
            recentsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            shutterButton.bottomAnchor.constraint(equalTo: recentsLabel.topAnchor, constant: -20),
            shutterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shutterButton.widthAnchor.constraint(equalToConstant: 68),
            shutterButton.heightAnchor.constraint(equalToConstant: 68)
        ])
    }

    // MARK: - Camera

    private func requestCameraAccess() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    granted ? self?.configureSession() : self?.showCameraDenied()
                }
            }
        default:
            showCameraDenied()
        }
    }

    private func configureSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            self.session.beginConfiguration()
            self.session.sessionPreset = .photo

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: device),
                  self.session.canAddInput(input),
                  self.session.canAddOutput(self.photoOutput)
            else {
                self.session.commitConfiguration()
                DispatchQueue.main.async { self.showCameraDenied() }
                return
            }

            self.session.addInput(input)
            self.session.addOutput(self.photoOutput)
            self.session.commitConfiguration()
            self.isSessionConfigured = true

            DispatchQueue.main.async { self.attachPreviewLayer() }
            self.session.startRunning()
        }
    }

    private func attachPreviewLayer() {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = previewContainer.bounds
        previewContainer.layer.insertSublayer(layer, at: 0)
        previewLayer = layer
    }

    private func showCameraDenied() {
        hintLabel.text = "Camera access is off. Enable it in Settings, or pick a recent photo below."
        shutterButton.isEnabled = false
        shutterButton.alpha = 0.4
        reticleView.stopScanning()
    }

    // MARK: - Recents

    private func loadRecentPhotos() {
        let handler: (PHAuthorizationStatus) -> Void = { [weak self] status in
            guard status == .authorized || status == .limited else { return }

            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            options.fetchLimit = 30
            options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)

            let result = PHAsset.fetchAssets(with: options)
            var assets: [PHAsset] = []
            result.enumerateObjects { asset, _, _ in assets.append(asset) }

            DispatchQueue.main.async {
                self?.recentAssets = assets
                self?.recentsCollectionView.reloadData()
                self?.recentsLabel.isHidden = assets.isEmpty
            }
        }

        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .readWrite, handler: handler)
        } else {
            handler(status)
        }
    }

    private func loadFullImage(for asset: PHAsset) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .none

        imageManager.requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { [weak self] image, info in
            // Can fire twice (degraded then full); only take the final image
            let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
            guard let image, !isDegraded else { return }
            self?.finish(with: image)
        }
    }

    // MARK: - Actions

    @objc private func handleShutter() {
        guard isSessionConfigured else { return }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        reticleView.flashCapture()

        let settings = AVCapturePhotoSettings()
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    @objc private func handleClose() {
        onCancel()
    }

    private func finish(with image: UIImage) {
        reticleView.stopScanning()
        onCapture(image)
    }
}

// MARK: - Photo capture

extension WFCameraScanViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else { return }
        DispatchQueue.main.async { [weak self] in self?.finish(with: image) }
    }
}

// MARK: - Recents strip

extension WFCameraScanViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        recentAssets.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: WFUIRecentPhotoCell.reuseID,
            for: indexPath
        ) as! WFUIRecentPhotoCell

        let asset = recentAssets[indexPath.item]
        cell.representedAssetIdentifier = asset.localIdentifier

        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true

        imageManager.requestImage(
            for: asset,
            targetSize: CGSize(width: 124, height: 124),
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            // Cell may have been recycled while the thumbnail was loading
            guard cell.representedAssetIdentifier == asset.localIdentifier else { return }
            cell.imageView.image = image
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        loadFullImage(for: recentAssets[indexPath.item])
    }
}

// MARK: - Subviews

/// Corner brackets plus a sweeping scan line.
final class WFUIScanReticleView: UIView {
    private let cornersLayer = CAShapeLayer()
    private let scanLine = UIView()
    private let scanGradient = CAGradientLayer()

    private var scanLineTopConstraint: NSLayoutConstraint?
    private var isAnimating = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear

        cornersLayer.strokeColor = UIColor.white.cgColor
        cornersLayer.fillColor = UIColor.clear.cgColor
        cornersLayer.lineWidth = 4
        cornersLayer.lineCap = .round
        layer.addSublayer(cornersLayer)

        scanLine.translatesAutoresizingMaskIntoConstraints = false
        scanLine.isUserInteractionEnabled = false
        scanGradient.colors = [
            UIColor.clear.cgColor,
            WFUIPalette.orange.withAlphaComponent(0.85).cgColor,
            UIColor.clear.cgColor
        ]
        scanGradient.startPoint = CGPoint(x: 0, y: 0.5)
        scanGradient.endPoint = CGPoint(x: 1, y: 0.5)
        scanLine.layer.addSublayer(scanGradient)
        addSubview(scanLine)

        let top = scanLine.topAnchor.constraint(equalTo: topAnchor)
        scanLineTopConstraint = top

        NSLayoutConstraint.activate([
            top,
            scanLine.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            scanLine.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            scanLine.heightAnchor.constraint(equalToConstant: 3)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        cornersLayer.frame = bounds
        cornersLayer.path = makeCornersPath().cgPath
        scanGradient.frame = scanLine.bounds
    }

    /// Four L-shaped brackets rather than a full rectangle.
    private func makeCornersPath() -> UIBezierPath {
        let path = UIBezierPath()
        let length = min(bounds.width, bounds.height) * 0.16
        let inset: CGFloat = 2

        let minX = bounds.minX + inset
        let maxX = bounds.maxX - inset
        let minY = bounds.minY + inset
        let maxY = bounds.maxY - inset

        // Top-left
        path.move(to: CGPoint(x: minX, y: minY + length))
        path.addLine(to: CGPoint(x: minX, y: minY))
        path.addLine(to: CGPoint(x: minX + length, y: minY))
        // Top-right
        path.move(to: CGPoint(x: maxX - length, y: minY))
        path.addLine(to: CGPoint(x: maxX, y: minY))
        path.addLine(to: CGPoint(x: maxX, y: minY + length))
        // Bottom-right
        path.move(to: CGPoint(x: maxX, y: maxY - length))
        path.addLine(to: CGPoint(x: maxX, y: maxY))
        path.addLine(to: CGPoint(x: maxX - length, y: maxY))
        // Bottom-left
        path.move(to: CGPoint(x: minX + length, y: maxY))
        path.addLine(to: CGPoint(x: minX, y: maxY))
        path.addLine(to: CGPoint(x: minX, y: maxY - length))

        return path
    }

    func startScanning() {
        guard !isAnimating else { return }
        isAnimating = true
        scanLine.isHidden = false
        runScanCycle()
    }

    func stopScanning() {
        isAnimating = false
        scanLine.layer.removeAllAnimations()
        scanLine.isHidden = true
    }

    private func runScanCycle() {
        guard isAnimating else { return }

        layoutIfNeeded()
        scanLineTopConstraint?.constant = 0
        layoutIfNeeded()

        UIView.animate(
            withDuration: 2.0,
            delay: 0,
            options: [.curveEaseInOut, .autoreverse, .repeat]
        ) {
            self.scanLineTopConstraint?.constant = self.bounds.height - 3
            self.layoutIfNeeded()
        }
    }

    /// Brief white flash when the shutter fires.
    func flashCapture() {
        let flash = UIView(frame: bounds)
        flash.backgroundColor = .white
        flash.alpha = 0
        addSubview(flash)

        UIView.animate(withDuration: 0.08, animations: {
            flash.alpha = 0.85
        }, completion: { _ in
            UIView.animate(withDuration: 0.22, animations: {
                flash.alpha = 0
            }, completion: { _ in
                flash.removeFromSuperview()
            })
        })
    }
}

final class WFUIRecentPhotoCell: UICollectionViewCell {
    static let reuseID = "WFUIRecentPhotoCell"

    var representedAssetIdentifier: String?

    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(imageView)
        contentView.layer.cornerRadius = 12
        contentView.layer.cornerCurve = .continuous
        contentView.clipsToBounds = true
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.white.withAlphaComponent(0.25).cgColor

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        representedAssetIdentifier = nil
    }
}
