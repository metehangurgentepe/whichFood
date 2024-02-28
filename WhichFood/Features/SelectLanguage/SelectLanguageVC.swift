//
//  SelectLanguageVC.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 7.11.2023.
//

import UIKit

class SelectLanguageVC: UIViewController {
    private lazy var tableView : UITableView = {
        let table = UITableView()
        table.register(LanguageTableViewCell.self, forCellReuseIdentifier: LanguageTableViewCell.identifier)
        table.separatorStyle = .none
        table.separatorInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        return table
    }()
    private lazy var viewModel = SelectLanguageViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.delegate = self
        viewModel.appendRowTableview()
        
        configure()
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    // design functions
    private func configure() {
        setupTable()
    }
}

// MARK: Design functions
extension SelectLanguageVC {
    private func setupTable() {
        view.addSubview(tableView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            
            tableView.heightAnchor.constraint(equalToConstant: view.bounds.height),
            tableView.widthAnchor.constraint(equalToConstant: view.bounds.width)
        ])
    }
}
// MARK: Table view functions
extension SelectLanguageVC : SelectLanguageViewModelProtocol{
    func handleViewModelOutput(_ output: SelectLanguageViewModelOutput) {
        switch output {
        case .showPopUp(vc: let vc):
            self.present(vc, animated: true)
        case .showError(let error):
            let alert = showAlert(title: "error", message: error.localizedDescription, buttonTitle: "OK", secondButtonTitle: "")
            self.present(alert, animated: true)
        }
    }
}
extension SelectLanguageVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.models.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: LanguageTableViewCell.identifier, for: indexPath) as! LanguageTableViewCell
        let model = viewModel.models[indexPath.row]
        cell.configure(with: model)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let function = viewModel.models[indexPath.row].handler
        function()
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
}
