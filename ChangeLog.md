# Replicator - Change Log

**v8.1.1**: 2025-06-30<br>
Address issues saving/displaying local file source path, show/hide credentials between launches. 
Address issue #123, exporting Patch Management, API roles / clients.
Better handling of concurrent requests and migration order.

**v8.1.0**: 2025-06-09<br>
Fix issue #122, username getting removed if URL contains a trailing /.
Fix app always running in debug mode.
Add replication of API Roles and Clients. Note, a new (different) client ID will be generated on the destinaion server.
Add support for multi-context environments.

**v8.0.2**: 2025-03-19<br>
Fix issue where a new version alert was displayed when the current version ran was the same as the latest release.

**v8.0.1**: 2025-03-15<br>
Fix issue were command line processing would stall. Better handling of command line export of smart/static objects. Better handling of credentials when switching servers (issues #118 and FR #119). Potentially fix application hanging (issue #117). Added new version check at application launch, alert can be silenced.

**v8.0.0**<br>
Fix command line usage, friendlier display of endpoints, better tracking of processes.

**v8.0.0-b3**<br>
Fix issue with Jamf Users and Jamf Groups. Fix issue when objects fail to replicate.

**v8.0.0-b2**<br>
Fix default download path. Fix existing objects not getting updated.

**v7.4.2**<br>
Resolve authentication impacting command line usage (issue #100) and initial token generation (issue #101).

**v7.4.1**<br>
Resolve issue with token renewal.  Resolve issue when running from the command line.  Resolve issue removing policies.  Resolve issue replicating self service icons.

**v7.4.0**<br>
Resolve scrolling issue with selective replications.  Better handling of computers/mobile devices with duplicate names.  Minor layout changes.  Ability to sort ascending or descending object list in selective replication. 

**v7.3.1**<br>
Work to resolve issue (#91), logging in with API clients.
Add option to copy only items not on the destination server - create only.
Add option to copy only items currently on both source and destination servers - update only.
Add option to set the number of servers/folders saved.

**v7.2.2**<br>
Fix version lookup with Jamf Pro 11, background threading issue.

**v7.2.1**<br>
Fix issue logging into Jamf Pro 11, issue #91.  Update token refresh method.

**v7.2.0**<br>
Add support for API client in both the UI and command line.

**v7.1.1**<br>
Prevent configuration profiles that include a Filevault payload from replicating.  Fix export of smart comuter/device groups.  Fix color mismatch (issue #88)

**v7.1.0**<br>
Command line functionality.  Note, -backup has been renamed -export and allows for specific types of objects to be exported.  Exported scripts no longer have characters XML encoded.  Expire tokens when quitting app.

**v7.0.2**<br>
Make disclosure triangle more visible in light mode with default color scheme
Fix counter when deleting items
better handling of access to previously selected folders
better handling of preferences as they are changed

**v7.0.1**<br>
prevent sleep while replicating
fix token refresh

**v7.0.0**<br>
Redesigned UI.  Add ability to show/hide username and password fields.  Replicate locally created classes and delete any class.  Add ability to force basic authentication.

**v6.3.0**<br>
Add ability to utilize selective replication while using exported files as the source.  Fix crash (issue #80) when Site is selected.  Show text while icons are being uploaded for self service policies and iOS apps.  Fix issue with selective replication of policies.

**v6.2.7**<br>
Fix crash when running on a machine for the first time (#79). Invalidate tokens when switching servers and stop token refresh once replication competes. Better user experience when working with export options and the disable export only button.

**v6.2.6**<br>
Fix issues #77 (self service display name) and #78 (crash when checking for updates)

**v6.2.5**<br>
Better handling of package filename/display name lookups.

**v6.2.4**<br>
* Fix credentials/servers not being saved.
* Fix token not refreshing.
* Disable destination server/credential fields if export only is detected at launch.
* Add disable export only button if setting is detected at app launch.  Button does not disable xml export, only the export only option.

**v6.2.2**<br>
* Better visual response when changing source/destination server.
* Fix authentication issue that resulted when the Jamf Pro web app was disabled.

**v6.2.1**<br>
* Fix site lookups (migrating to a site) when using bearer token.
* Fix issue where categories were not created when need be during dependency replication (policies).
* Update version check alert to focus on new version if available.
* Add warning about not being able to use Save Only while in delete mode.
* Add ability to replicate iOS devices to a site on the same server.

**v6.2.0**<br>
* Fix filenames that get characters xml encoded when importing files.
* Improved icon handling, determine appropriate location for the upload.  If cloud servicers connection is enable self service icons will update within the policy.
* Add support for Bearer authentication to the classic API.
* Fix issues on importing files from previously selected folder.
* Misc code cleanup.

**v6.0.1**<br>
* Allow replication of computers to a site.  
* Moved show summary under View in the menu bar.  Add ability to toggle delete mode under View in the menu bar.
* Progress bar changes color as failurs occur.
* Provide a warning if a single package filename is referenced by multiple package display names.  Will not create duplicate references on the destination server.
* Buildings are replicated with full address information.
* Selective replication of multiple policies with replicate dependencies selected is more reliable.
* Handle netboot servers being removed from Jamf Pro.
* Fix issue with some buttons used with bulk replications.

**v5.9.3**<br>
* Fixed issue saving files with names that contain a / (forward slash). Noted the : (colon) is a reserved character and cannot be used in a file name, ; (semi-colon) will be subtituted for it.  This does not impact the name that appears in Jamf Pro.

**v5.9.2**<br>
* Fixed issue with self service icons when cloud services connector is not referenced.

**v5.9.1**<br>
* Fixed issue self service icon replications.

**v5.9.0**<br>
* With great sadness (computer) configurations have been removed as an object that can be replicated.
* Added ability to select the location of exported files.
* Fixed crash that would occur when importing files while on the Selective tab.
* Add command line options for setting an ldap id on jamf user accounts and converting standard jamf accounts to ldap accounts.

**v5.8.3**<br>
* Fix animation not stopping under certain conditions when no objects are found to replicate.
* Fix issue where policies would list multiple times in selective mode.

**v5.8.2**<br>
* Change filter, add button to clear filter
* Remember permissions on folder selected for file imports.
* Add browse button for selecting folder of import files.
* Resolve crashes when application is first run on a machine.

**v5.8.0**<br>
* Chasing down miscellaneous crashes.
* Test authentication against the restrictedsoftware API endpoint (instead of buildings), allowing site admins to use the app.
* Add ability to filter objects listed when doing a selective replication.

**v5.7.0**<br>
* Better handling of Help window.
* Better results when hitting the STOP button
* Interface clean-up.
* Miscellaneous code fixes.

**v5.6.2**<br>
* Resolve crash when importing files located outside the ~/Downloads folder.
* Resolved issue related to replicating the computer as managed.
* Added option to remove conditional acccess ID from computer reccord.
* Better handling of preferences window when it is in the backcground.

**v5.6.0**<br>
* Ability to move users to a particular site.
* Ability to set computer management account.
* Ability to set a password for service accounts associated with bind, ldap, and file share resources.

**v5.4.0**<br>
* Resolve fix issue (#57), app crashing when copy preferences are changed.
* Removed select all/none checkbox.  Toggle all/none by holding the option key down when selecting a class of objects to replicate.
* Add ability to set concurrent API operations (from 1 to 20) and set the number of log files to keep.
* Update readme and help.

**v5.3.2**<br>
* Resolve issue replicating self service icons when using files as the source. 

**v5.3.1**<br>
* Replaced use of curl to upload icons with native Swift functions. If the same Self Service icon is used on more then one policy, download icon only once. 
* Fixed jamf user/group lookups and counter status/labeling.
* Clear current list of objects on the selective tab if the source server changes.
* Fix issue replicating computers where their inventory contains a volume of size 0 or negative partition size.

**v5.2.9**<br>
* Prevent icon from being deleted before it is saved when using save only.  Note, if saving both raw and trimmed XML the icon will only be saved under the raw folder.  If saving only trimmed XML it will be saved under the trimmed folder.

**v5.2.8**<br>
* Tweaked icon download routine.

**v5.2.7**<br>
* Changes on icon replication, where they're cached and check for a successful upload, retry if it failed.  
* Resolved issue where query would hang when looking to delete policies (and there were none) and saving xml was enabled.

**v5.2.5**<br>
* Resolve issue (#53) when using LDAP groups in limitations/exclusions.
* Resolve miscelaneous 404 errors in the log. 

**v5.2.3**<br>
* Added code to prevent the UUID of macOS configuration profiles from potentially being changed during an update.  Credit to @grahampugh for identifying (and blogging about) the issue.
  
**v5.2.2**<br>
* Code cleanup and fix issue (#50) where app would crash if preference for saveRawXmlScope was missing.

**v5.2.1**<br>
* Fixed smart/static group lookups giving 404 responses.

**v5.2.0**<br>
* Exporting (saving) raw or trimmed XML now has the to include/exclude the scope.
* Updated help.
* Better handleing in bringing the preferences window to the foreground when it is already open, but behind another window.

**v5.1.0**<br>
* Addressed several issues around GET and POST counters, including issues #43 and #48.
* Updated UI.  Replaced POST with either POST/PUT (for replications) or DELETE (for removals), issue #47.
* Fixed issue where user/iOS device/computer groups would not replicate if they were the last item to replicate.
* Allow resizing of summary window.
* Resolved issues around replicating policies along with their dependencies in the proper order.
* Added summary for items removed.

**v5.0.3**<br>
* Provide additional logging around icon replication.  Slight change in process (issue #46).
* Better handling of Jamf Pro API (UAPI) calls.
* Use encoding different than what the Jamf server uses for the ampersand in the name of a macOS configuration profile (issue #45).

**v5.0.1**<br>
* Fix app crashes during XML export.

**v5.0.0**<br>
* Introduce smart selective replications for policies.  When replicating a policy dependent items (scripts, packages, printers, computer groups, ...) will also be replicated/updated, if desired.  Only 'top-level' dependencies are checked.  i.e. if the scope of a policy is being replicated and contains nested computer groups or groups assigned to a site that doesn't exist on the destination server the policy replication will likely fail.  Adding smart replications is planned for other items.
* Resolve problem of replicating LDAP Jamf User Groups to Jamf Pro v10.17+ (issue #42).

**v4.1.3**<br>
* Resolved app crash when doing a selective replication on groups.

**v4.1.2**<br>
* Added site None to list of available sites to replicate to.  
* Increased concurrent threads for post/put/delete from 1 to 3.  
* Speedier listing of objects when using selective replication.

**v4.1.0**<br>
* Added the ability to replicate disk encryption configurations.  Since passwords cannot be replicated Institutional configurations containing the private key will not replicate.

**v4.0.0**<br>
* Added the ability to replicate objects (groups, policies, and configuration profiles) to a particular site, either on the source server or another server.
* Re-added button to bring up preferences.  

**v3.3.5**<br>
* Resovled script parameter issue (#34)

**v3.3.4**<br>
* Resovled display issue with High Sierra (issue #31)
* Resovled issue where blank lines were removed from scripts when replicated (issue #33)

**v3.3.3**<br>
* Markdown formatting and spelling corrections.  Thanks @homebysix

**v3.3.2**<br>
* Fixed issue where icons were not replicating
* Fixed app crash issue (#28) that resulted when running in removal mode and no credentials were entered for the source server.
  
**v3.3.0**<br>
* Adjustment to the GUI for Dark Mode
* App is now sandboxed, hardened, and notarized
* Updated help with new images and file paths
  
**v3.2.2**<br>
* Fixed issue #24, group and policy selective removal broken.
* Changed arrangement of drop-downs on selective to align with suggested replication order.
* Split selective replication/removal or group items into smart and static.
* Fixed issue where the listing of items in selective mode would not refresh as desired.

**v3.2.0**<br>
* Tabs reordered, General tab is now first to align with suggested replication order.
* Updated tabs/buttons used for navigating between General, macOS, iOS, and Selective sections.
* Buttons for items to replicate are off by default when the app is launched.
* You can now switch back and forth between removal and replication modes using &#8984;D.
* When using the Selective tab, items are removed from the list as they are deleted from the server.  Once all selected items are removed the list is grayed out.
* Fixed an issue with Policies and Selective replication where the app could become unresponsive.  Policies should be listed much more quickly.
* Fixed an issue where groups would not be listed when working with the Selective tab.
* Fixed potential crash when importing a software update server from an XML file.
* Fixed issue where xxxgroup would be displayed along with staticxxxgroup and smartxxxgroup in the summary.
* Fixed an issue where a computer record would get resubmitted indefinitely.
* Fixed issued with log file names.
* Fixed issue where replication order might not go as designed.

**v3.1.0**<br>
* Resolved app crashes when exporting XML and destination server field is blank.
* Resolved potential app hanging when replicating extension attributes that include patch policy EAs.
* Re-tool preferences.
* Removed preferences button and help button to prevent duplicate windows from opening.
* Resolved issue where scripts could get corrupted when replication.
    
**v3.0.6**<br>
* Items will now replicate if category, building, or department is missing on the destination server. The field will be blanked out to allow the replication.

**v3.0.5**<br>
* Policies with the Account payload can now be replicated.  **Note:** Account password is set to `jamfchangeme`.
* Resolved an issue where a smart group with thousands of computers would not get cleared.
* Resolved issue replicating machines with duplicate serial numbers or MAC addresses.  Duplicate addresses are cleared.
* Resolved issue trying to copy computers with no serial number.
* Resolved issue where a policy name starting with a space would lose the leading space when it was posted to the new server.
* References to the source server in the App Config are now updated to the destination server.

**v3.0.0**<br>
* Added ability to use locally stored XML files as a source rather than a server.
* Added ability to replicate macOS and iOS Mac App Store apps.

**v2.8.0**<br>
* Moved text manipulation to main thread, fixing issues where the endpoint URL was incorrect.
* **Changed tab order** - tabs through server to username to password.
* Updated replication order to address issue #18.
* Removed forced debug mode accidentally left in the previous beta.
* Lightly grayed out GET/POST related fields to indicate they are not for user input.
* Added button for quick access to preferences and help.
* Help window can now be displayed while running replications.
* Changes to the GUI, moved tabs to top of section and added arrows to selective replication subjects.
* Added removing the scope from static computer groups/mobile device groups/user groups, addressing issue #19.
* Grayed out source server when doing removals to make it more clear from which server items get removed.
* Updated Help.
* Added 'check for updates...' under Replicator in the menu bar.
* Added additional logging, in debug mode. Minor code adjustments.
* Added ability to export xml. Added cache clearing to authentication / server availability check in an effort to resolve 503 errors when the api is actually available.

**v2.7.2**<br>
* Corrected encoding issue (#17) of special characters that caused authentication failures.

**v2.6.3**<br>
* Corrected an issued with self service icons not replicating if the icon name contained a space.

**v2.6.2**<br>
* Resolve issue #14, items not replicating in the proper order.

**v2.6.0**<br>
* Deferrals no longer stripped from policies.
* Only log xml from failed items when in debug mode.
* More informative logging, give reason of failure along with http status code.
* Move history files to ~/Library/Logs/Replicator and change extension to log. Refer to them as log files now.
* Added summary to provide count of items created, updated, and failed (&#8984;S) after a replication run.
* Patch Extension Attributes are no longer replicated.
* Log file naming has been corrected, for future logging. Current logs named incorrectly need to be manually deleted or renamed. Issue#13
* Added recommended replication and dependencies to help. Issue#12
* Replication of icons used in self service for newly created policies. Updating an existing policy will not update the existing icon on the destination server.

**v2.2.5**<br>
* Added replication of computer configurations.  Note, it is possible to delete the parent of a smart configuration, thus orphaning the 'child' config.  An orphaned child configuration is not accessible through the API, as a result it cannot be replicated.  In the event the orphaned child configuration(s) also has child configuration(s), those child configuration(s) are turned into parent configuration(s).
* Added ability to select frequently used source/destination servers from the user interface.  Up to 10 server are selectable by using the up/down arrows to the right of the URL text box.

**v2.1.5**<br>
* Added replication of dock items.
* Added stop button to stop the replication in progress.
  
**v2.1.4**<br>
* Added replication of directory bindings.
  
**v2.1.3**<br>
* Fixed smart group replication failures when done selectively.
* Fixed advanced computer search duplication if replicated more then once, they should update now if changed.
* Fixed authentication verification when Jamf Server utilizes SSO (thanks @ftiff).

**v2.1.0**<br>
* Added the ability to replicate Jamf server accounts (users and groups).  Newly created accounts on the destination server will be created without a password (can't replicate passwords).  The account being used to authenticate to the destination server is not replicated if it also exists on the source server.  The replication of accounts depends on the existence of related sites and LDAP servers in order to be successful.
   
**v2.0.0**<br>
* Change to the user interface.  Grouped similar categories together.
* Added iOS items.
* Selective replication now allows the selection of multiple items, using control and/or shift key.
* Added selective removal of items within a category.

**v1.2.1**<br>
* fixed issue where app would hang if last/only item replicated had no endpoints.
* credentials no longer needed for source server when removing data.
* UI button improvements for select all/none (thanks @jdhovaland).

**v1.2.0**<br>
* Fixed the issue replicating computers with the xprotect tag having no value.
* Selective replication now lists endpoints alpha-numeric.
* Added debug logging. To enable, launch the app from terminal:

```
…/Replicator.app/Contents/MacOS/Replicator –debug
```

* Debug info is added to the history file
* Easily open the history folder from View on the menu bar, or &#8984;L

