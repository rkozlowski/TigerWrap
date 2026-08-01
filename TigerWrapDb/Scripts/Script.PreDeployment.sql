/*
 Pre-Deployment Script Template							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be executed before the build script.	
 Use SQLCMD syntax to include a file in the pre-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the pre-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/

/*
	The two includes below are MUTUALLY EXCLUSIVE. Exactly one of them must be
	active when a release artifact is generated:

	  UPGRADE artifact      -> Script.PreUpgradeVersionCheck.sql active
	                           (check the expected source/target versions in it
	                            and in Script.Version.sql first)
	  FULL DEPLOY artifact  -> Script.PreInstallEmptyCheck.sql active

	Generating an artifact with the wrong guard active produces either an upgrade
	that refuses every valid target, or a full install with no protection at all.
	ItTiger.TigerWrap.Tests/InstallGuardArtifactTests.cs asserts that the packaged
	full deploy artifact contains the install guard before the first CREATE SCHEMA.

	Currently active: FULL DEPLOY. The last generated artifact is
	DeploymentScripts/TigerWrapDb_FullDeploy_v_0.9.2.sql. Flip the toggle back
	before generating an upgrade artifact.

	Released artifacts are never regenerated in place: a change to this project
	produces a new versioned file (see Script.Version.sql) and the previously
	released files stay byte-for-byte as shipped.
*/

-- note: uncomment below line only for generating upgrade script (and make sure the versions in the script below and in the version script are set up correctly
--:r .\Script.PreUpgradeVersionCheck.sql
-- note: uncomment below line only for generating the full deploy (install) script
:r .\Script.PreInstallEmptyCheck.sql
