#if defined _friendlysimple_included
  #endinput
#endif
#define _friendlysimple_included

public SharedPlugin:__pl_friendlysimple = {
	name = "Friendly Simple",
	file = "friendlysimple.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_friendlysimple_SetNTVOptional(){

	MarkNativeAsOptional("FriendlySimple_IsFriendly");
	MarkNativeAsOptional("FriendlySimple_IsInSpawn");
	MarkNativeAsOptional("FriendlySimple_HasAccess");
	MarkNativeAsOptional("FriendlySimple_SetFriendly");

}
#endif



	/****************************\
		-	F O R W A R D S  -
	\****************************/


/**
 * Called during a player's transition into Friendly Mode. This fires before any
 * changes are applied but after the client notification.
 *
 * @param client		Client Index.
 */
forward FriendlySimple_OnEnableFriendly(client);


/**
 * Called during a player's transition out of Friendly Mode. This fires before any
 * changes are applied but after the client notification. Note that it also fires
 * for every client upon unloading/reloading friendlysimple.smx.
 *
 * @param client		Client Index.
 */
forward FriendlySimple_OnDisableFriendly(client);




	/**************************\
		-	N A T I V E S  -
	\**************************/


/**
 * Returns whether or not a given player is Friendly.
 *
 * @param client		Client Index.
 * @return				TRUE if Friendly, FALSE if not Friendly or if invalid client.
 */
native bool:FriendlySimple_IsFriendly(client);


/**
 * Returns whether or not a given player is in their spawn.
 *
 * @param client		Client Index.
 * @return				TRUE if is in their spawn, FALSE if not in their spawn or if invalid client.
 */
native bool:FriendlySimple_IsInSpawn(client);


/**
 * Returns whether or not a given player has access to Friendly.
 *
 * @param client		Client Index.
 * @return				TRUE if has access, FALSE if doesn't have access or if invalid client.
 */
native bool:FriendlySimple_HasAccess(client);


/**
 * Sets Friendly mode on a client.
 *
 * @param client		Client Index.
 * 
 * @param direction		-1 to toggle, 0 to disable, or 1 to enable
 * 
 * @return				-3 if client is not a valid client index,
 * 						-2 if client is not connected and in game,
 * 						-1 if no change was made (the client was already in the requested state)
 * 						0 if the player was made non-Friendly,
 * 						1 if the player was made Friendly.
 */
native FriendlySimple_SetFriendly(client, direction=-1);