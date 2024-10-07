//
//  AccountViewModel.swift
//  WhichFood
//
//  Created by Metehan Gürgentepe on 10.11.2023.
//

import Foundation
import RevenueCat
import FirebaseFirestore


final class AccountViewModel: AccountViewModelProtocol {

    weak var delegate: AccountViewModelDelegate?
    
    private (set) var user : User?
    private (set) var models = [AccountInfo]()
    
    
    @MainActor
    func getUser(completion: @escaping () -> Void) {
        self.delegate?.handleViewModelOutput(.setLoading(true))
        Task { [weak self] in
            guard let self = self else { return }
            do {
                self.user = try await UserManager.shared.getUser()
                if let user = self.user {
                    self.delegate?.handleViewModelOutput(.getUser(user))
                    self.delegate?.handleViewModelOutput(.setLoading(false))
                    completion()
                }
            } catch {
                self.delegate?.handleViewModelOutput(.setLoading(false))
                self.delegate?.handleViewModelOutput(.showError(error))
            }
        }
    }

    
    @MainActor
    func createTableView() {
        getUser { [weak self] in
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
