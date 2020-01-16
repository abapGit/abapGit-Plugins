[![abaplint](https://app.abaplint.org/badges/larshp/abapGit-Plugins)](https://app.abaplint.org/project/larshp/abapGit-Plugins)

These plugins will sometime become obsolete, see https://github.com/larshp/abapGit/issues/1449 and https://github.com/larshp/abapGit/pull/1590

# abapGit-Plugins
This repository contains plugins for abapGit to support other objecttypes. 
By inheriting from `zcl_abapgitp_object`and implementing `zif_abapgitp_plugin` you can create plugins for objecttypes which are not natively supported by ABAPGit yet.
However, please be aware that the format used by ABAPGit may change, so please check back frequently to make sure your plugin stays up-to-date.

# SOBJ-based generic plugin
One plugin already contained in this repository is a generic plugin supporting multiple object types. Similar to the SAP transport management system, it transports table content. As this is quite a dangerous operation (particularly when operating across systems with potentially different releases), you should check your systems technical components and the one from which you import the repository.
