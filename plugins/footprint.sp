#include <sourcemod>
#include <tf2attributes>
#include <donator>
new Handle:db = INVALID_HANDLE;
new Float:FootprintID[MAXPLAYERS+1] = 0.0;
new bool:foot_random[MAXPLAYERS+1];
new sql_foot_id[MAXPLAYERS+1];
new sql_random_foot[MAXPLAYERS+1];
public OnPluginStart()
{
	decl String:error[256];
	db = SQL_Connect("footprint", true, error, sizeof(error));
	if(db==INVALID_HANDLE) {
		LogError("Could not connect to database: %s", error);
		return;
	}
	SQL_TQuery(db, SQLErrorCheckCallback, "CREATE TABLE IF NOT EXISTS footprint_table (steamid TEXT, footprint_id INTEGER, random_foot INTEGER)");
	HookEvent("player_spawn", PlayerSpawn, EventHookMode_Post);
}
public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data) {
	if(!StrEqual("", error)) {
		LogError("Query failed: %s", error);
	}
}
public OnAllPluginsLoaded()
{
	if(!LibraryExists("donator.core")) SetFailState("Unabled to find plugin: Basic Donator Interface");
	Donator_RegisterMenuItem("Set Footprint", ChangeFootTestCallBack);
}
public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(FootprintID[client] > 0.0)
	{
		TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", FootprintID[client]);
	}
	if (foot_random[client])
	{
		SetRandomFoot(client);
	}
	if (isMaxPlayer())
	{
		TF2Attrib_RemoveByName(client, "SPELL: set Halloween footstep type");
	}
}
public SetRandomFoot(client)
{
	if(foot_random[client])
	{
		new Float:dbg = GetRandomFloat(1.0, 999999999.0);
		TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", dbg);
		PrintToConsole(client, "Client: %N Code: %f", client, dbg);
	}
}
public DonatorMenu:ChangeFootTestCallBack(client)
{
	new Handle:FootMenu = CreateMenu(FootSwitch);
	SetMenuTitle(FootMenu, "Footprint Menu");
	AddMenuItem(FootMenu, "0", "Select footprint");
	AddMenuItem(FootMenu, "1", "Random footprint");
	AddMenuItem(FootMenu, "2", "Delete footprint");

	SetMenuExitButton(FootMenu, true);
	DisplayMenu(FootMenu, client, MENU_TIME_FOREVER);
}
public FootSwitch(Handle:menu, MenuAction:action, client, args)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		if(args == 0)
		{
			SelectFootPrint(client);
		}
		else if (args == 1)
		{
			decl String:query[124], String:clientid[32];
			FootprintID[client] = 0.0;
			foot_random[client] = true;
			sql_foot_id[client] = 0;
			sql_random_foot[client] = 1;
			GetClientAuthString(client, clientid, sizeof(clientid));
			Format(query, sizeof(query), "SELECT * FROM footprint_table WHERE steamid='%s'", clientid);
			SQL_TQuery(db, SQLQueryInsert, query, GetClientUserId(client));
			SetRandomFoot(client);
		}
		else if(args == 2)
		{
			decl String:query[124], String:clientid[32];
			FootprintID[client] = 0.0;
			foot_random[client] = false;
			sql_foot_id[client] = 0;
			sql_random_foot[client] = 0;
			GetClientAuthString(client, clientid, sizeof(clientid));
			Format(query, sizeof(query), "SELECT * FROM footprint_table WHERE steamid='%s'", clientid);
			SQL_TQuery(db, SQLQueryInsert, query, GetClientUserId(client));
			TF2Attrib_RemoveByName(client, "SPELL: set Halloween footstep type");
		}
	}
}
public SQLQueryInsert(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
	if((client = GetClientOfUserId(data))==0)
	{
		return;
	}
	if(hndl==INVALID_HANDLE)
	{
		LogError("Query failed: %s", error);
	}
	else
	{
		decl String:query[512], String:clientid[32];
		GetClientAuthString(client, clientid, sizeof(clientid));
		if(!SQL_MoreRows(hndl))
		{
			Format(query, sizeof(query), "INSERT INTO footprint_table VALUES('%s', '%i', '%i')", clientid, sql_foot_id[client], sql_random_foot[client]);
			SQL_TQuery(db, SQLErrorCheckCallback, query);
		}
		else
		{
			Format(query, sizeof(query), "UPDATE footprint_table SET footprint_id=%i,random_foot=%i WHERE steamid='%s'", sql_foot_id[client], sql_random_foot[client], clientid);
			SQL_TQuery(db, SQLErrorCheckCallback, query);
		}
	}
}
SelectFootPrint(client)
{
	new Handle:SelectMenu = CreateMenu(FootprintHandle);
	SetMenuTitle(SelectMenu, "Select Footprint:");
	AddMenuItem(SelectMenu, "1", "Team Based");
	AddMenuItem(SelectMenu, "7777", "Blue");
	AddMenuItem(SelectMenu, "933333", "Light Blue")
	AddMenuItem(SelectMenu, "8421376", "Yellow");
	AddMenuItem(SelectMenu, "4552221", "Corrupted Green");
	AddMenuItem(SelectMenu, "3100495", "Dark Green");
	AddMenuItem(SelectMenu, "51234123", "Lime");
	AddMenuItem(SelectMenu, "5322826", "Brown");
	AddMenuItem(SelectMenu, "8355220", "Oak Tree Brown");
	AddMenuItem(SelectMenu, "13595446", "Flames");
	AddMenuItem(SelectMenu, "8208497", "Cream");
	AddMenuItem(SelectMenu, "41234123", "Pink");
	AddMenuItem(SelectMenu, "300000", "Satan's Blue");
	AddMenuItem(SelectMenu, "2", "Purple");
	AddMenuItem(SelectMenu, "3", "Black");
	AddMenuItem(SelectMenu, "83552", "Ghost In The Machine");
	AddMenuItem(SelectMenu, "9335510", "Holy Flame");
	AddMenuItem(SelectMenu, "46337", "Green");
	AddMenuItem(SelectMenu, "6879521", "s1");
	AddMenuItem(SelectMenu, "6454678", "s2");
	AddMenuItem(SelectMenu, "22422342", "s3");
	AddMenuItem(SelectMenu, "366597889", "s4");
	AddMenuItem(SelectMenu, "13435978", "s5");
	SetMenuExitButton(SelectMenu, true);
	DisplayMenu(SelectMenu, client, MENU_TIME_FOREVER);
}
public FootprintHandle(Handle:menu, MenuAction:action, client, args)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[12], String:query[124], String:clientid[32];
		GetMenuItem(menu, args, info, sizeof(info));
		new weapon_glow = StringToInt(info);
		FootprintID[client] = float(weapon_glow);
		foot_random[client] = false;
		sql_foot_id[client] = weapon_glow;
		sql_random_foot[client] = 0;
		GetClientAuthString(client, clientid, sizeof(clientid));
		Format(query, sizeof(query), "SELECT * FROM footprint_table WHERE steamid='%s'", clientid);
		SQL_TQuery(db, SQLQueryInsert, query, GetClientUserId(client));
		TF2Attrib_SetByName(client, "SPELL: set Halloween footstep type", FootprintID[client]);
	}
}
public OnClientPostAdminCheck(client)
{
	if(!IsFakeClient(client))
	{
		decl String:clientid[32], String:query[256];
		new userid = GetClientUserId(client);
		GetClientAuthString(client, clientid, sizeof(clientid));
		Format(query, sizeof(query), "SELECT footprint_id,random_foot FROM footprint_table WHERE steamid='%s'", clientid);
		SQL_TQuery(db, SQLQueryConnect, query, userid);
	}
}
public SQLQueryConnect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
	new temp_foot_id;
	new temp_random;
	if((client = GetClientOfUserId(data))==0)
	{
		return;
	}
	if(hndl==INVALID_HANDLE)
	{
		LogError("Query failed: %s", error);
	}
	else
	{
		if(!SQL_MoreRows(hndl))
		{
			FootprintID[client] = 0.0;
			foot_random[client] = false;
			return;
		}
		while(SQL_FetchRow(hndl))
		{
			temp_foot_id = SQL_FetchInt(hndl, 0);
			temp_random = SQL_FetchInt(hndl, 1);
		}
		IntToType(client, temp_foot_id, temp_random);
	}
}
public IntToType(client, temp_foot_id, temp_random)
{
	if (temp_foot_id >= 0)
	{
		FootprintID[client] = float(temp_foot_id);
		foot_random[client] = false;
	}
	if (temp_random == 1)
	{
		foot_random[client] = true;
		FootprintID[client] = 0.0;
	}
}
bool:isMaxPlayer()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && i > 6)
		{
			if (GetClientTeam(i) == 2 || GetClientTeam(i) == 3)
			{
				return true;
			}
		}
	}
	return false;
}