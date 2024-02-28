//
//  AccountViewModel.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 10.11.2023.
//

import Foundation
import RevenueCat
import FirebaseFirestore

enum AccountViewModelOutput {
    case getUser(User)
    case showError(Error)
    case setLoading(Bool)
    case getTableViews([AccountInfo])
    case tappedRow(index:Int)
    case navigate(vc: UIViewController)
}

protocol AccountViewModelProtocol {
    var delegate: AccountViewModelDelegate? {get set}
    func getUser(completion: @escaping () -> Void)
    func createTableView()
}

final class AccountViewModel: AccountViewModelProtocol {

    weak var delegate: AccountViewModelDelegate?
    
    private (set) var user : User?
    private (set) var models = [AccountInfo]()
    
    // user service yaz
    @MainActor
    func getUser(completion: @escaping () -> Void) {
        self.delegate?.handleViewModelOutput(.setLoading(true))
        Task { [weak self] in
            do {
                self?.user = try await UserManager.shared.getUser()
                if let user = self?.user {
                    self?.delegate?.handleViewModelOutput(.getUser(user))
                    completion()
                }
            } catch {
                self?.delegate?.handleViewModelOutput(.showError(error))
            }
        }
    }

    @MainActor 
    func createTableView() {
        // Call getUser with a completion handler
        print(user?.lastPremiumDate?.description)
        getUser { [weak self] in
            // Now the user property is populated
            self?.models.append(AccountInfo(
                title: LocaleKeys.AccountScreen.idName.rawValue.locale(),
                content: self?.user?.id ?? LocaleKeys.AccountScreen.id.rawValue.locale(),
                handler: {
                    self?.delegate?.handleViewModelOutput(.tappedRow(index:0))
                }))
            self?.models.append(AccountInfo(
                title: LocaleKeys.AccountScreen.premiumName.rawValue.locale(),
                content: self?.user?.premiumType ?? LocaleKeys.AccountScreen.premium.rawValue.locale(),
                handler: {
                    let premiumVC = PremiumVC()
                    self?.delegate?.handleViewModelOutput(.navigate(vc: premiumVC))
                }))
            self?.models.append(AccountInfo(
                title: LocaleKeys.AccountScreen.dateName.rawValue.locale(),
                content:  formatDate(self?.user?.lastPremiumDate) ?? LocaleKeys.AccountScreen.date.rawValue.locale(),
                handler: {
                    
                }))
            self?.models.append(AccountInfo(
                title: LocaleKeys.AccountScreen.numberOfUsageApi.rawValue.locale(),
                content:  String(self?.user?.numberOfUsageApi ?? 0) ,
                handler: {
                    
                }))
            self?.delegate?.handleViewModelOutput(.getTableViews(self?.models ?? []))
        }
    }
}
