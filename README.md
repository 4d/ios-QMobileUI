# QMobileUI

[Development #88648](https://project.wakanda.org/issues/88648)

a DataSource object implement `UITableViewDataSource` and `UICollectionViewDataSource` to provide to `UITableView` and `UICollectionView` records from `DataStore` `FetchedResultsController`

`DataSource` implement `FetchedResultsControllerDelegate` to listen to `DataStore` `FetchedResultsController` change

A delegate on `DataSource` could
- provide some additional table or view configuration (ex: how to fill the table or collection view cell)
- be notified of content change
- ...


 __/!\__ you cannot change the dataSource attribute of TableView/CollectionView yourself when using DataSource

---

An example is provided into "Example" folder in QMobileUI repository

In `UITableViewController`
```swift
let fetchedResultsController = dataStore.fetchedResultsController(tableName: "tableName")
let dataSource = DataSource(tableView: self.tableView, fetchedResultsController: fetchedResultsController)
```
