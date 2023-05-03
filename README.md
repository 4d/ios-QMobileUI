# QMobileUI

This iOS framework belong to [iOS SDK](https://github.com/4d/ios-sdk) and it contains :
- graphical views ie. the navigation, list, details and action forms
  - code to bind data to views
  - code to send actions and retry according to network status
- services that the mobile application needs. (see `Application`

## How it workds

### List forms

List form contains a DataSource object that implement `UITableViewDataSource` and `UICollectionViewDataSource` to provide to `UITableView` and `UICollectionView` records from `DataStore` `FetchedResultsController`

`DataSource` implement `FetchedResultsControllerDelegate` to listen to `DataStore` `FetchedResultsController` change

A delegate on `DataSource` could
- provide some additional table or view configuration (ex: how to fill the table or collection view cell)
- be notified of content change
- etc ...

```swift
let fetchedResultsController = dataStore.fetchedResultsController(tableName: "tableName")
let dataSource = DataSource(tableView: self.tableView, fetchedResultsController: fetchedResultsController)
```

### Application services

A service listen to application lifecycle event and execute events. For instance at start of application, database, logging, preferences, etc... are configured.

The [`QApplication`](Sources/Application/QApplication.Swift) instance replace the default application instance and allow to initialize a set of services.

See [Sources/Application/Services](Sources/Application/Services) for a list of installed services.

New one could be created and injected, see [tutorial](https://github.com/4d-go-mobile/sdk/blob/master/docs/ApplicationService.md)

## Dependencies

| Name | License | Usefulness |
|-|-|-|
| [QMobileAPI](https://github.com/4d/ios-QMobileAPI) | [4D](https://github.com/4d/ios-QMobileAPI/blob/master/LICENSE.md) | Network api |
| [QMobileDataStore](https://github.com/4d/ios-QMobileDataStore) | [4D](https://github.com/4d/ios-QMobileDataStore/blob/master/LICENSE.md) | Store data |
| [QMobileDataSync](https://github.com/4d/ios-QMobileDataSync) | [4D](https://github.com/4d/ios-QMobileDataSync/blob/master/LICENSE.md) | Synchronize data |
