//
//  CategoryViewController.swift
//  Todoey
//
//  Created by Angel Solorio on 2/1/19.
//  Copyright © 2019 Angel Solorio. All rights reserved.
//

import UIKit
import CoreData

class CategoryViewController: UITableViewController {
    var categoryArray = [Category]()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    override func viewDidLoad() {
        super.viewDidLoad()

        // Display an Edit button in the navigation bar for this view controller.
        self.editButtonItem.tintColor = .white
        self.navigationItem.leftBarButtonItem = self.editButtonItem

        loadCategories()
    }


    // MARK: - Tableview Datasource Methods

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categoryArray.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath)
        cell.textLabel?.text = categoryArray[indexPath.row].name

        return cell
    }


    // MARK: - Tableview Delegate Methods

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "goToItems", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
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
     }

    // Support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    // Support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let alert = UIAlertController(title: nil, message: "Are you sure you want to DELETE this Category?", preferredStyle: .actionSheet)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let removeAction = UIAlertAction(title: "Delete", style: .destructive) { (action) in
                self.context.delete(self.categoryArray[indexPath.row])
                self.categoryArray.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .fade)
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
        tableView.reloadData()
    }


    // MARK: - IBActions

    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        var textField = UITextField()
        let alert = UIAlertController(title: "Add New Category", message: "", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
        let addAction = UIAlertAction(title: "Add", style: .default) { (action) in
            if textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                let newCategory = Category(context: self.context)
                newCategory.name = textField.text
                self.categoryArray.append(newCategory)
                self.saveCategories()
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
