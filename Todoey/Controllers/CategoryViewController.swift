//
//  CategoryViewController.swift
//  Todoey
//
//  Created by Angel Solorio on 2/1/19.
//  Copyright © 2019 Angel Solorio. All rights reserved.
//

import UIKit
import RealmSwift
import ChameleonFramework

class CategoryViewController: UITableViewController {
    let realm = try! Realm()
    var categories: Results<Category>?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Display an Edit button in the navigation bar for this view controller.
        editButtonItem.tintColor = .white
        navigationItem.leftBarButtonItem = editButtonItem

        loadCategories()
    }

    override func viewDidAppear(_ animated: Bool) {
        // Customize the navigation bar
        guard let navBar = self.navigationController?.navigationBar else {fatalError("Navigation Controller does not exists.")}
        navBar.prefersLargeTitles = false
        navBar.barTintColor = UIColor(hexString: "1D9BF6")
        navBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
    }


    // MARK: - Tableview Datasource Methods

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        editButtonItem.isEnabled = categories?.count ?? 0 > 0 ? true : false
        return categories?.count ?? 0 > 0 ? categories!.count : 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath)
        if categories?.count ?? 0 > 0 {
            // Customize cells to display the Categories
            let category = categories![indexPath.row]
            let backgroundColor = UIColor(hexString: category.color)
            let textColor = UIColor(contrastingBlackOrWhiteColorOn: backgroundColor, isFlat: true)
            cell.textLabel?.text = category.name
            cell.textLabel?.textColor = textColor
            cell.textLabel?.textAlignment = .left
            cell.backgroundColor = backgroundColor
            cell.tintColor = textColor
            cell.accessoryType = .disclosureIndicator
        } else {
            // Customize a cell to display a message to the user to a a new Category
            cell.textLabel?.text = "Add a new Category tapping on the + button."
            cell.textLabel?.textColor = UIColor.gray
            cell.textLabel?.textAlignment = .center
            cell.backgroundColor = .clear
            cell.accessoryType = .none
        }

        return cell
    }


    // MARK: - Tableview Delegate Methods

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if categories?.count ?? 0 > 0 {
            performSegue(withIdentifier: "goToItems", sender: self)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    // Support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    // Support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        tableView.moveRow(at: fromIndexPath, to: to)
        moveCategory(fromIndex: fromIndexPath.row, toIndex: to.row)
        tableView.reloadData()
    }

    // Support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return categories?.count ?? 0 > 0 ? true : false
    }

    // Support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete && categories?.count ?? 0 > 0 {
            let alert = UIAlertController(title: nil, message: "Are you sure you want to DELETE this Category?", preferredStyle: .actionSheet)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let removeAction = UIAlertAction(title: "Delete", style: .destructive) { (action) in
                self.deleteCategory(atIndex: indexPath.row)
                self.tableView.reloadData()
            }
            alert.addAction(removeAction)
            alert.addAction(cancelAction)

            self.present(alert, animated: true, completion: nil)
        }
    }


    // MARK: - Data Manipulation Methods

    func loadCategories() {
        categories = realm.objects(Category.self).sorted(byKeyPath: "index", ascending: true)
        tableView.reloadData()
    }

    func save(category: Category) {
        let nextIndex = (realm.objects(Category.self).max(ofProperty: "index") as Int? ?? 0) + 1
        category.index = nextIndex

        do {
            try realm.write {
                realm.add(category)
            }
        } catch {
            print("Error saving data in Realm, \(error)")
        }
    }

    func deleteCategory(atIndex index: Int) {
        if let category = categories?[index] {
            do {
                try realm.write {
                    realm.delete(category)
                }
            } catch {
                print("Error deleting a Category in realm, \(error)")
            }
        }
    }

    func moveCategory(fromIndex: Int, toIndex: Int) {
        guard fromIndex != toIndex else { return }
        if let categoryMoved = categories?[fromIndex] {
            let isMovingUp = fromIndex > toIndex ? true : false
            let predicate = isMovingUp ? "index BETWEEN {\(toIndex + 1), \(fromIndex)}" : "index BETWEEN {\(fromIndex + 2), \(toIndex + 1)}"
            let rowsToMove = realm.objects(Category.self).filter(predicate)
            do {
                try realm.write {
                    for category in rowsToMove {
                        category.index = isMovingUp ? category.index + 1 : category.index - 1
                    }
                    categoryMoved.index = toIndex + 1
                }
            } catch {
                print("Error moving a Category in realm, \(error)")
            }
        }
    }


    // MARK: - IBActions

    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        var textField = UITextField()
        let alert = UIAlertController(title: "Add New Category", message: "", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
        let addAction = UIAlertAction(title: "Add", style: .default) { (action) in
            let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            if text != nil && text != "" {
                // Create a new Category
                let newCategory = Category()
                newCategory.name = text!
                newCategory.color = UIColor(randomFlatColorOf: .light).hexValue()

                self.save(category: newCategory)
                self.tableView.reloadData()
            }
        }
        alert.addTextField { (alertTextField) in
            // Customize textfield
            alertTextField.placeholder = "Add a new Category"
            alertTextField.autocapitalizationType = .words
            alertTextField.enablesReturnKeyAutomatically = true
            alertTextField.returnKeyType = .done
            textField = alertTextField
        }
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        alert.preferredAction = addAction

        self.present(alert, animated: true, completion: nil)
    }


    // MARK: - Segguence

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! TodoListViewController
        if let indexPath = tableView.indexPathForSelectedRow {
            destinationVC.selectedCategory = categories?[indexPath.row]
        }
    }
}
