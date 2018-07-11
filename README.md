# Jamf Migrator
A tool to migrate data granularly between Jamf Pro servers

![alt text](https://github.com/jamfprofessionalservices/JamfMigrator/blob/master/jamf-migrator/images/migrator2.png "JamfMigrator")

Download: [JamfMigrator](https://github.com/jamfprofessionalservices/JamfMigrator/releases/download/current/jamf-migrator.zip)

Feedback in the GUI gives a simplistic overview of the success of a transfer:
* Green - everything transferred.
* Yellow - some items transferred.
* Red - nothing transferred.
* White - nothing to transfer.


Information about successes/failures can be found in the log, located in 

```~/Library/Logs/jamf-migrator/<date>_<time>_migration.log```

**Note:** the app can also be used to clear out a Jamf server.  Typing the following after launching the app will set it into removal mode.  Items from the destination server are deleted once Go is clicked.

```touch ~/Library/Application\ Support/jamf-migrator/delete```

**Migration Options:**<p>
* You can remove the scope as some items are transfered as well as disable policies that are migrated.
 
![](https://github.com/jamfprofessionalservices/JamfMigrator/blob/master/jamf-migrator/images/copy_migrator_prefs.png)
 
 * XML can be exported if desired.
 
![](https://github.com/jamfprofessionalservices/JamfMigrator/blob/master/jamf-migrator/images/export_migrator_prefs.png)
 

**Limitations/requirements to be aware of:**
* Passwords can not be extracted through the API which impacts migrating distribution points, computer management account, account used for LDAP - credentials must be reset on the destination server.
* Only AFP and SMB shares can be migrated.
* Patch management is not available through the API impacting smart groups dependent on patch management extension attributes.
* Buildings - the API only allows the name to be migrated.
* If enpoints (computers, policies, configuration profiles...) have duplicate names on the source server issues will arise if the app is used to update those items from the source to destination server.

**Migration Summary:**<p>
* To get details on how many items were created/updated or failed to migrate type ⌘S, or select Show Summary under the File menu.
  
  ![alt text](https://github.com/jamfprofessionalservices/JamfMigrator/blob/master/jamf-migrator/images/summary1.png "Summary")
  
* Additional information about each count can be obtained by clicking on the number. For example, if we want to see a list of the 28 failed scripts, click on the 28.
  
  ![alt text](https://github.com/jamfprofessionalservices/JamfMigrator/blob/master/jamf-migrator/images/summary2.png "Summary Details")
  
**Important:**<p>
* There are many dependancies between items, if they are not met transfers fail.  For example, if a policy is site specific the site must be migrated before the policy; if a distribution point has a building and/or department defined those need to migrate first...  If everything is migrated the order of sections is already taken care of, if you choose not to move some items that's where you can have issues.
* Summary window doesn't seem to be the most responsive.  May need to click the window or give the cursor some extra motion before the detailed summary appears.


## History
**v2.8.0**<p>
* Moved text manipulation to main thread, fixing issues where the endpoint URL was incorrect.
* **Changed tab order** - tabs through server to username to password.
* Updated migration order to address issue #18.
* Removed forced debug mode accidentally left in the previous beta.
* Lightly grayed out GET/POST related fields to indicate they are not for user input.
* Added button for quick access to preferences and help.
* Help window can now be displayed while running migrations.
* Changes to the GUI, moved tabs to top of section and added arrows to selective migration subjects.
* Added removing the scope from static computer groups/mobile device groups/user groups, addressing issue #19.
* Grayed out source server when doing removals to make it more clear from which server items get removed.
* Updated Help.
* Added 'check for updates...' under jamf-migrator in the menu bar.
* Added additional logging, in debug mode. Minor code adjustments.
* Added ability to export xml. Added cache clearing to authentication / server availability check in an effort to resolve 503 errors when the api is actually available.

**v2.7.2**<p>
* Corrected encoding issue (#17) of special characters that caused authentication failures.

**v2.6.3**<p>
* Corrected an issued with self service icons not migrating if the icon name contained a space.

**v2.6.2**<p>
* Resolve issue #14, items not migrating in the proper order.

**v2.6.0**<p>
* Deferrals no longer stripped from policies.
* Only log xml from failed items when in debug mode.
* More informative logging, give reason of failure along with http status code.
* Move history files to ~/Library/Logs/jamf-migrator and change extension to log. Refer to them as log files now.
* Added summary to provide count of items created, updated, and failed (command+s) after a migration run.
* Patch Extension Attributes are no longer migrated.
* Log file naming has been corrected, for future logging. Current logs named incorrectly need to be manually deleted or renamed. Issue#13
* Added recommended migration and dependencies to help. Issue#12
* Migration of icons used in self service for newly created policies. Updating an existing policy will not update the existing icon on the destination server.

**v2.2.5**<p>
* Added migration of computer configuratons.  Note, it is possible to delete the parent of a smart configuration, thus orphaning the 'child' config.  An orphaned child configuration is not accessible through the API, as a result it cannot be migrated.  In the event the orphaned child configuration(s) also has child configuration(s), those child configuration(s) are turned into parent configuration(s).
* Added ability to select frequently used source/destination servers from the user interface.  Up to 10 server are selectable by using the up/down arrows to the right of the URL text box.

**v2.1.5**<p>
* Added migration of dock items.
* Added stop button to stop the migration in progess.
  
**v2.1.4**<p>
* Added migration of directory bindings.
  
**v2.1.3**<p>
* Fixed smart group migration failures when done selectively.
* Fixed advanced computer search duplication if migrated more then once, they should update now if changed.
* Fixed authentication verification when Jamf Server utilizes SSO (thanks @ftiff).

**v2.1.0**<p>
* Added the ability to migrate Jamf server accounts (users and groups).  Newly created accounts on the destination server will be created without a password (can't migrate passwords).  The account being used to authenticate to the destination server is not migrated if it also exists on the source server.  The migration of accounts depends on the existence of related sites and LDAP servers in order to be successful.
   
**v2.0.0**<p>
* Change to the user interface.  Grouped similar categories together.
* Added iOS items.
* Selective migration now allows the selection of multiple items, using control and/or shift key.
* Added selective removal of items within a category.

**v1.2.1**<p>
* fixed issue where app would hang if last/only item migrated had no endpoints.
* credentials no longer needed for source server when removing data.
* UI button improvememts for select all/none (thanks @jdhovaland).

**v1.2.0**<p>
* Fixed the issue migrating computers with the xprotect tag having no value.
* Selective migration now lists endpoints alpha-numeric.
* Added debug logging. To enable, launch the app from terminal:

```…/jamf-migrator.app/Contents/MacOS/jamf-migrator –debug```

* Debug info is added to the history file
* Easily open the history folder from View on the menu bar, or command+L

