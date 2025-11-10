//
//  ViewController.swift
//  InspoQuotes
//
//  Created by Alexandra on 6.11.25.
//

import UIKit
import StoreKit

class QuoteTableViewController: UITableViewController {
    
    var quotesToShow = [
        "Our greatest glory is not in never falling, but in rising every time we fall. — Confucius",
        "All our dreams can come true, if we have the courage to pursue them. – Walt Disney",
        "It does not matter how slowly you go as long as you do not stop. – Confucius",
        "Everything you’ve ever wanted is on the other side of fear. — George Addair",
        "Success is not final, failure is not fatal: it is the courage to continue that counts. – Winston Churchill",
        "Hardships often prepare ordinary people for an extraordinary destiny. – C.S. Lewis"
    ]
    
    let premiumQuotes = [
        "Believe in yourself. You are braver than you think, more talented than you know, and capable of more than you imagine. ― Roy T. Bennett",
        "I learned that courage was not the absence of fear, but the triumph over it. The brave man is not he who does not feel afraid, but he who conquers that fear. – Nelson Mandela",
        "There is only one thing that makes a dream impossible to achieve: the fear of failure. ― Paulo Coelho",
        "It’s not whether you get knocked down. It’s whether you get up. – Vince Lombardi",
        "Your true success in life begins only when you make the commitment to become excellent at what you do. — Brian Tracy",
        "Believe in yourself, take on your challenges, dig deep within yourself to conquer fears. Never let anyone bring you down. You got to keep going. – Chantal Sutherland"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isPurchased() {
            showPremiumQuotes()
        }
    }
    
    func showPremiumQuotes() {
        quotesToShow.append(contentsOf: premiumQuotes)
        tableView.reloadData()
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return quotesToShow.count + (isPurchased() ? 0 : 1)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Outlets.TableView.ReusableCell.quoteCell, for: indexPath)
        
        var config = cell.defaultContentConfiguration()
        if indexPath.row >= quotesToShow.count {
            config.text = Constants.Labels.QuoteTableView.getMoreQuotes
            config.textProperties.color = UIColor.blue
            cell.accessoryType = .disclosureIndicator
        } else {
            config.text = quotesToShow[indexPath.row]
            config.textProperties.color = UIColor.black
            cell.accessoryType = .none
        }
        cell.contentConfiguration = config
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == quotesToShow.count {
            Task {
                await buyPremiumQuotes()
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - In-App Purchase
    
    func buyPremiumQuotes() async {
        if AppStore.canMakePayments {
            do {
                let products = try await fetchProducts()
                if products.count == 0 {
                    return
                }
                
                let result = try await products[0].purchase()
                switch result {
                case .success(let verificationResult):
                    switch verificationResult {
                    case .verified(let transaction):
                        print("verified")
                        await transaction.finish()
                        processPurchase()
                        showPremiumQuotes()
                    case .unverified(_, let verificationError):
                        print("unverified. Error: \(verificationError)")
                    }
                case .pending:
                    // requires Transaction.updates implementation
                    print("pending")
                    break
                case .userCancelled:
                    print("userCancelled")
                    break
                @unknown default:
                    break
                }
                
            } catch {
                print(error)
                return
            }
        }
    }
    
    func fetchProducts() async throws -> [Product] {
        let storeProducts = try await Product.products(for: [Constants.InAppPurchases.premiumQuotes])
        return storeProducts
    }
    
    func isPurchased() -> Bool {
        return UserDefaults.standard.bool(forKey: Constants.InAppPurchases.premiumQuotes)
    }
    
    func processPurchase() {
        UserDefaults.standard.set(true, forKey: Constants.InAppPurchases.premiumQuotes)
    }
}
