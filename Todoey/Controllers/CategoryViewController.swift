//
//  CategoryViewController.swift
//  Todoey
//
//  Created by Angel Solorio on 2/1/19.
//  Copyright © 2019 Angel Solorio. All rights reserved.
//

import UIKit
import CoreData
import ChameleonFramework

class CategoryViewController: UITableViewController {
    var categoryArray = [Category]()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
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
        editButtonItem.isEnabled = categoryArray.count > 0 ? true : false
        return categoryArray.count > 0 ? categoryArray.count : 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath)
        if categoryArray.count > 0 {
            // Customize cells to display the Categories
            let category = categoryArray[indexPath.row]
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
        if categoryArray.count > 0 {
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
        let element = categoryArray.remove(at: fromIndexPath.row)
        categoryArray.insert(element, at: to.row)
        saveCategories()
        tableView.reloadData()
    }

    // Support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return categoryArray.count > 0 ? true : false
    }

    // Support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete && categoryArray.count > 0 {
            let alert = UIAlertController(title: nil, message: "Are you sure you want to DELETE this Category?", preferredStyle: .actionSheet)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let removeAction = UIAlertAction(title: "Delete", style: .destructive) { (action) in
                self.context.delete(self.categoryArray[indexPath.row])
                self.categoryArray.remove(at: indexPath.row)
                self.saveCategories()
                self.tableView.reloadData()
            }
            alert.addAction(removeAction)
            alert.addAction(cancelAction)

            self.present(alert, animated: true, completion: nil)
        }
    }


    // MARK: - Data Manipulation Methods

    func loadCategories(with request: NSFetchRequest<Category> = Category.fetchRequest()) {
        do {
            categoryArray = try context.fetch(request)
        } catch  {
            print("Error fetching data from context \(error)")
        }
        tableView.reloadData()
    }

    func saveCategories() {
        do {
            try context.save()
        } catch {
            print("Error saving data in context \(error)")
        }
    }


    // MARK: - IBActions

    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        var textField = UITextField()
        let alert = UIAlertController(title: "Add New Category", message: "", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
        let addAction = UIAlertAction(title: "Add", style: .default) { (action) in
            let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            if text != "" {
                // Create a new Category
                let newCategory = Category(context: self.context)
                newCategory.name = text
                newCategory.color = UIColor(randomFlatColorOf: .light).hexValue()

                self.categoryArray.append(newCategory)
                self.saveCategories()
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
            destinationVC.selectedCategory = categoryArray[indexPath.row]
        }
    }
}
