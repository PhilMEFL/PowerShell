# Localized	03/24/2018 06:38 PM (GMT)	303:4.80.0411 	Configure-ServerManagerStandardUserRemoting.psd1


ConvertFrom-StringData @'
###PSLOC
ErrorOnUsernameMessage=L’objet spécifié n’existe pas ou n’est pas un utilisateur : {0}
ConfirmEnableMessage=Ajouter des utilisateurs aux groupes {0} ?\nCette action donne également aux utilisateurs des droits d’accès « Activer le compte » et « Sécurité de lecture » sur l’espace de noms WMI root\\cimv2, et octroie aux utilisateurs des droits d’accès sur les éléments suivants dans le gestionnaire de contrôle des services : SC_MANAGER_CONNECT, SC_MANAGER_ENUMERATE_SERVICE, SC_MANAGER_QUERY_LOCK_STATUS et STANDARD_RIGHTS_READ
ConfirmDisableMessage=Supprimer des utilisateurs des groupes {0} ?\nCette action supprime également tous les droits d’accès pour ces utilisateurs sur l’espace de noms WMI root\\cimv2, et supprime tous les droits d’accès dans le gestionnaire de contrôle des services pour ces utilisateurs.
ShouldProcessForUserMessage=Activer l’administration à distance pour l’utilisateur standard {0}
ShouldProcessForUserMessageDisable=Désactiver l’administration à distance pour l’utilisateur standard {0}
###PSLOC

'@
