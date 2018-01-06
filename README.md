# JamfMigrator
A tool to migrate data granularly between Jamf Pro servers

![alt text](https://github.com/jamfprofessionalservices/JamfMigrator/blob/master/jamf-migrator/images/migrator2.png "JamfMigrator")

Download: [JamfMigrator](https://github.com/jamfprofessionalservices/JamfMigrator/releases/download/current/jamf-migrator.zip)

Feedback in the GUI gives a simplistic overview of the success of a transfer:
* Green - everything transferred.
* Yellow - some items transferred.
* Red - nothing transferred.
* White - nothing to transfer.


A more detailed review of migration successes/failures can be found in the log, located in `~/Library/Application Support/jamf-migrator/history/<date>_<time>_migration.txt.`

**Note:** the app can also be used to clear out a Jamf server.  Typing the following after launching the app will set it into removal mode.  Items from the destination server are deleted once Go is clicked.

```touch ~/Library/Application\ Support/jamf-migrator/DELETE```

**Limitations/requirements to be aware of:**
* Passwords can not be extracted through the API which impacts migrating distribution points, computer management account, account used for LDAP - credentials must be reset on the destination server.
* Only AFP and SMB shares can be migrated.
* Patch management is not available through the API impacting smart groups dependent on patch management extension attributes.
* Buildings - the API only allows the name to be migrated.
* If enpoints (computers, policies, configuration profiles...) have duplicate names on the source server issues will arise if the app is used to update those items from the source to destination server.

**Important:**<p>
* There are many dependancies between items, if they are not met transfers fail.  For example, if a policy is site specific the site must be migrated before the policy; if a distribution point has a building and/or department defined those need to migrate first...  If everything is migrated the order of sections is already taken care of, if you choose not to move some items that's where you can have issues.
* The selective migration still needs some work.  App is easily crashed by dragging objects other than those from the source server to the destination server.


## History
**jamf-migrator v2.2.5**<p>
* Added migration of computer configuratons.  Note, it is possible to delete the parent of a smart configuration, thus orphaning the 'child' config.  An orphaned child configuration is not accessible through the API, as a result it cannot be migrated.  In the event the orphaned child configuration(s) also has child configuration(s), those child configuration(s) are turned into parent configuration(s).
* Added ability to select frequently used source/destination servers from the user interface.  Up to 10 server are selectable by using the up/down arrows to the right of the URL text box.

**jamf-migrator v2.1.5**<p>
* Added migration of dock items.
* Added stop button to stop the migration in progess.
  
  
**jamf-migrator v2.1.4**<p>
* Added migration of directory bindings.
  
  
**jamf-migrator v2.1.3**<p>
* Fixed smart group migration failures when done selectively.
* Fixed advanced computer search duplication if migrated more then once, they should update now if changed.
* Fixed authentication verification when Jamf Server utilizes SSO (thanks @ftiff).


**jamf-migrator v2.1.0**<p>
* Added the ability to migrate Jamf server accounts (users and groups).  Newly created accounts on the destination server will be created without a password (can't migrate passwords).  The account being used to authenticate to the destination server is not migrated if it also exists on the source server.  The migration of accounts depends on the existence of related sites and LDAP servers in order to be successful.
  
  
**jamf-migrator v2.0.0**<p>
* Change to the user interface.  Grouped similar categories together.
* Added iOS items.
* Selective migration now allows the selection of multiple items, using control and/or shift key.
* Added selective removal of items within a category.


**jamf-migrator v1.2.1**<p>
* fixed issue where app would hang if last/only item migrated had no endpoints.
* credentials no longer needed for source server when removing data.
* UI button improvememts for select all/none (thanks @jdhovaland).


**jamf-migrator v1.2.0**<p>
* Fixed the issue migrating computers with the xprotect tag having no value.
* Selective migration now lists endpoints alpha-numeric.
* Added debug logging. To enable, launch the app from terminal:

```…/jamf-migrator.app/Contents/MacOS/jamf-migrator –debug```

* Debug info is added to the history file
* Easily open the history folder from View on the menu bar, or command+L

