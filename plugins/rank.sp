//	AuthId_Steam2,         /**< Steam2 rendered format, ex "STEAM_1:1:4153990" */
//	AuthId_Steam3,         /**< Steam3 rendered format, ex "[U:1:8307981]" */
//	AuthId_SteamID64,      /**< A SteamID64 (uint64) as a String, ex "76561197968573709" */

#include <sourcemod>
#include <morecolors>
#include <geoip>
#define PLUGIN_VERSION "1.0.559"
new Handle:db = INVALID_HANDLE;
new totalCount;
new String:NamePlayer[40];
new ratingPlayer;
new pointcountPlayer;
new killPlayer;
new deathPlayer;
new RankSpeed;
new SpeedPlayer;
new DeflectPlayer;
new SumDeflectPlayer;
new playtimePlayer;
new rank[MAXPLAYERS+1];
new rating[MAXPLAYERS+1];
new kills[MAXPLAYERS+1];
new deaths[MAXPLAYERS+1];
new speed[MAXPLAYERS+1];
new deflect[MAXPLAYERS+1];
new sumdeflect[MAXPLAYERS+1];
new playtime[MAXPLAYERS+1];
new sessionrating[MAXPLAYERS+1];
new sessionkills[MAXPLAYERS+1];
new sessiondeaths[MAXPLAYERS+1];
new sessionplaytime[MAXPLAYERS+1]
new String:ranklog[PLATFORM_MAX_PATH];
public Plugin:myinfo =
{
	name = "Ranking",
	author = "AJAX",
	description = "Top players and top speed.",
	version = PLUGIN_VERSION,
	url = "ajax.com"
};
public OnPluginStart() {
	decl String:error[256];
	db = SQL_Connect("rank", true, error, sizeof(error));
	if(db==INVALID_HANDLE) {
		LogError("Could not connect to database: %s", error);
		return;
	}
	SQL_TQuery(db, SQLErrorCheckCallback, "CREATE TABLE IF NOT EXISTS stats (steamid TEXT, name TEXT, rating INTEGER, kills INTEGER, deaths INTEGER, speed INTEGER, deflect INTEGER, sumdeflect INTEGER, playtime INTEGER)");
	RegConsoleCmd("say", Command_say);
	RegConsoleCmd("say_team", Command_say);
	RegConsoleCmd("sm_top", Top_target, "Top_target.", 0);
	RegConsoleCmd("sm_rank", Top_target, "Top_target.", 0);
	RegConsoleCmd("sm_ts", Top_Speed, "Top_Speed.", 0);
	RegConsoleCmd("sm_setpoint", SetPoint, "SetPoint.", 0);
	RegAdminCmd("sm_ts_reset", ResetSpeed, ADMFLAG_GENERIC);
	HookEvent("player_death", Event_player_death);
	CreateTimer(60.0, Name_Check, _, TIMER_REPEAT);
	CreateTimer(60.0, Time_Update, _, TIMER_REPEAT);
	new String:ftime[86];
	FormatTime(ftime, sizeof(ftime), "logs/rank/logs%m-%d-%y.txt");
	BuildPath(Path_SM, ranklog, sizeof(ranklog), ftime);
}
public Action ResetSpeed(int client, args) 
{
	SQL_TQuery(db, SQLErrorCheckCallback, "UPDATE stats SET speed='0',deflect='0'");
	return Plugin_Handled;
}
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("rank");
	CreateNative("SetSpeed", Native_SetSpeed);
	CreateNative("SetDeflect", Native_SetDeflect);
	CreateNative("SetSumDeflect", Native_SetSumDeflect);
	CreateNative("GetSpeed", Native_GetSpeed);
	CreateNative("GetDeflect", Native_GetDeflect);
	return APLRes_Success;
}
public Native_SetSpeed(Handle:plugin, params)
{
	decl String:SteamID[36], String:query[100];
	new client = GetNativeCell(1);
	speed[client] = GetNativeCell(2);
	GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
	Format(query, sizeof(query), "UPDATE stats SET speed='%i' WHERE steamid='%s'", speed[client], SteamID);
	SQL_TQuery(db, SQLErrorCheckCallback, query);
}
public Native_SetDeflect(Handle:plugin, params)
{
	decl String:SteamID[36], String:query[100];
	new client = GetNativeCell(1);
	deflect[client] = GetNativeCell(2);
	GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
	Format(query, sizeof(query), "UPDATE stats SET deflect='%i' WHERE steamid='%s'", deflect[client], SteamID);
	SQL_TQuery(db, SQLErrorCheckCallback, query);
}
public Native_SetSumDeflect(Handle:plugin, params)
{
	decl String:SteamID[36], String:query[100];
	new client = GetNativeCell(1);
	sumdeflect[client]++;
	GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
	Format(query, sizeof(query), "UPDATE stats SET sumdeflect='%i' WHERE steamid='%s'", sumdeflect[client], SteamID);
	SQL_TQuery(db, SQLErrorCheckCallback, query);
}
public Native_GetSpeed(Handle:plugin, params)
{
	new client = GetNativeCell(1);
	if(IsClientInGame(client) && !IsFakeClient(client)){
		return speed[client];
	}
	return 0;
}
public Native_GetDeflect(Handle:plugin, params) //  params = id client
{
	new client = GetNativeCell(1);
	if(IsClientInGame(client) && !IsFakeClient(client)){
		return deflect[client];
	}
	return 0;
}
public Action:Top_target(client, args)
{
	decl String:strTarget[36];
	if(args < 1)
	{
		return Plugin_Handled;
	}
	GetCmdArg(1, strTarget, sizeof(strTarget));
	decl String:query[160];
	Format(query, sizeof(query), "SELECT name,rating,kills,deaths,speed,deflect,sumdeflect,playtime FROM stats WHERE name='%s'", strTarget);
	SQL_TQuery(db, SQLQueryRankCheck, query, GetClientUserId(client));
	return Plugin_Handled;
}
public Action:Top_Speed(client, args)
{
	decl String:strTarget[36];
	if(args < 1)
	{
		return Plugin_Handled;
	}
	GetCmdArg(1, strTarget, sizeof(strTarget));
	decl String:query[160];
	Format(query, sizeof(query), "SELECT name,speed,deflect,sumdeflect FROM stats WHERE name='%s'", strTarget);
	SQL_TQuery(db, SQLQueryTSCheck, query, GetClientUserId(client));
	return Plugin_Handled;
}
public Action:SetPoint(client, args)
{
	decl String:strTarget[36];
	if(args < 1)
	{
		return Plugin_Handled;
	}
	GetCmdArg(1, strTarget, sizeof(strTarget));
	char arg1[16] = "";
	GetCmdArg(2, arg1, sizeof(arg1));
	int point = StringToInt(arg1);
	decl String:query[160];
	Format(query, sizeof(query), "UPDATE stats SET rating='%i' WHERE name='%s'", point, strTarget);
	SQL_TQuery(db, SQLErrorCheckCallback, query);
	return Plugin_Handled;
}
public Action:Name_Check(Handle:hTimer)
{
	for (new iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsClientInGame(iClient) && !IsFakeClient(iClient))
		{
			decl String:steamId[36], String:name[72], String:query[140];
			GetClientAuthId(iClient, AuthId_Steam2, steamId, sizeof(steamId));
			GetClientName(iClient, name, sizeof(name));
			ReplaceString(name, sizeof(name), "'", "");
			ReplaceString(name, sizeof(name), "<?", "");
			ReplaceString(name, sizeof(name), "?>", "");
			ReplaceString(name, sizeof(name), "`", "");
			ReplaceString(name, sizeof(name), ",", "");
			ReplaceString(name, sizeof(name), "<?PHP", "");
			ReplaceString(name, sizeof(name), "<?php", "");
			ReplaceString(name, sizeof(name), "<", "[");
			ReplaceString(name, sizeof(name), ">", "]");
			Format(query, sizeof(query), "UPDATE stats SET name = '%s' WHERE steamid = '%s'", name, steamId);
			SQL_TQuery(db,SQLErrorCheckCallback, query);
		}
	}
}
public Action:Time_Update(Handle:hTimer)
{
	for (new iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsClientInGame(iClient) && !IsFakeClient(iClient))
		{
			decl String:steamId[36], String:query[140];
			GetClientAuthId(iClient, AuthId_Steam2, steamId, sizeof(steamId));
			playtime[iClient]++;
			sessionplaytime[iClient]++;
			Format(query, sizeof(query), "UPDATE stats SET playtime = '%i' WHERE steamid = '%s'", playtime[iClient], steamId);
			SQL_TQuery(db,SQLErrorCheckCallback, query);
		}
	}
}
public OnClientPostAdminCheck(client)
{
	if(!IsFakeClient(client) && client > 0)
	{
		CreateTimer(2.0, Timer_PrintConnect, GetClientUserId(client));
	}
	if(!IsFakeClient(client) && IsClientInGame(client) && client > 0) {
	decl String:clientid[36], String:query[160];
	new userid = GetClientUserId(client);
	GetClientAuthId(client, AuthId_Steam2, clientid, sizeof(clientid));
	if (strlen(clientid) > 8)
	{
		Format(query, sizeof(query), "SELECT rating,kills,deaths,speed,deflect,sumdeflect,playtime FROM stats WHERE steamid='%s'", clientid);
		SQL_TQuery(db, SQLQueryConnect, query, userid);
	} else
	{
		KickClient(client, "The target was not found.");
	}
	SQL_TQuery(db, Query_GetRecordCount, "SELECT COUNT(*) FROM stats");
	sessionrating[client] = 0;
	sessionkills[client] = 0;
	sessiondeaths[client] = 0;
	sessionplaytime[client] = 0;
}
}
public Action:Timer_PrintConnect(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client > 0)
	{
		decl String:query[100];
		Format(query, sizeof(query), "SELECT * FROM stats WHERE rating>'%i'", rating[client]);
		SQL_TQuery(db, SQLQueryPrint, query, GetClientUserId(client));
	}
}
public SQLQueryPrint(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
	if((client = GetClientOfUserId(data))==0) {
		return;
	}
	if(hndl==INVALID_HANDLE){
		LogError("Query failed: %s", error);
	}
	else{
		rank[client] = SQL_GetRowCount(hndl) + 1;
	}
	PrintToChatAll("\x073EFF3E%N\x01 has joined the game and is ranked \x073EFF3E#%i\x01 out of \x073EFF3E%i\x01 players with \x073EFF3E%i\x01 Points!", client, rank[client], totalCount, rating[client]);
}
public Query_GetRecordCount(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl==INVALID_HANDLE)
	{
		LogError("Query failed: %s", error);
		return;
	}
	if (SQL_FetchRow(hndl) == true)
		totalCount = SQL_FetchInt(hndl, 0) + 1;
}
public SQLQueryConnect(Handle:owner, Handle:hndl, const String:error[], any:data) {
	new client;
	if((client = GetClientOfUserId(data))==0) {
		return;
	}
	if(hndl==INVALID_HANDLE) {
		LogError("Query failed: %s", error);
	} else {
		decl String:query[160], String:clientname[40], String:clientid[40];
		GetClientName(client, clientname, sizeof(clientname));
		ReplaceString(clientname, sizeof(clientname), "'", "");
		GetClientAuthId(client, AuthId_Steam2, clientid, sizeof(clientid));
		if(!SQL_MoreRows(hndl)) {
			Format(query, sizeof(query), "INSERT INTO stats VALUES('%s', '%s', 1000, 0, 0, 0, 0, 0, 0)", clientid, clientname); // стимид, ник, очки, килы, смерти, скорость, отражения
			SQL_TQuery(db, SQLErrorCheckCallback, query);
			rating[client] = 1000;
			kills[client] = 0;
			deaths[client] = 0;
			speed[client] = 0;
			deflect[client] = 0;
			sumdeflect[client] = 0;
			playtime[client] = 0;
		} else {
			Format(query, sizeof(query), "UPDATE stats SET name='%s' WHERE steamid='%s'", client, clientname, clientid);
			SQL_TQuery(db, SQLErrorCheckCallback, query);
		}
		while(SQL_FetchRow(hndl)) {
			rating[client] = SQL_FetchInt(hndl, 0);
			kills[client] = SQL_FetchInt(hndl, 1);
			deaths[client] = SQL_FetchInt(hndl, 2);
			speed[client] = SQL_FetchInt(hndl, 3);
			deflect[client] = SQL_FetchInt(hndl, 4);
			sumdeflect[client] = SQL_FetchInt(hndl, 5);
			playtime[client] = SQL_FetchInt(hndl, 6);
		}
	}
}
public SQLQueryTS(Handle:owner, Handle:hndl, const String:error[], any:data) {
	new client;
	if((client = GetClientOfUserId(data))==0) {
		return;
	}
	if(hndl==INVALID_HANDLE) {
		LogError("Query failed: %s", error);
	} 
	else {
		new i = 1;
		decl String:PlayerName[40], String:PlayerID[40], String:menuline[40];
		new Handle:menu = CreateMenu(TSMenuHandler1);
		while (SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl,0, PlayerName , 40);
			SQL_FetchString(hndl,1, PlayerID , 40);
			Format(menuline, sizeof(menuline), "%i. %s", i, PlayerName);
			AddMenuItem(menu, PlayerID, menuline);
			i++;
		}
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, 60);
	}
}
public TSMenuHandler1(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:info[40], String:buffer[160];
		GetMenuItem(menu, param2, info, sizeof(info));
		Format(buffer, sizeof(buffer), "SELECT name,speed,deflect,sumdeflect FROM stats WHERE steamid='%s'", info);
		SQL_TQuery(db, SQLQueryTSCheck, buffer, GetClientUserId(param1));
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
public SQLQueryTSCheck(Handle:owner, Handle:hndl, const String:error[], any:data) {
	new client;
	if((client = GetClientOfUserId(data))==0) {
		return;
	}
	if(hndl==INVALID_HANDLE) {
		LogError("Query failed: %s", error);
	} else {
		if(!SQL_MoreRows(hndl)){
			PrintToChat(client, "The target was not found.");
			return;
		}
		while(SQL_FetchRow(hndl)) {
			SQL_FetchString(hndl, 0, NamePlayer, 40);
			SpeedPlayer = SQL_FetchInt(hndl, 1);
			DeflectPlayer = SQL_FetchInt(hndl, 2);
			SumDeflectPlayer = SQL_FetchInt(hndl, 3);
		}
	}
	decl String:query[80];
	Format(query, sizeof(query), "SELECT * FROM stats WHERE speed>'%i'", SpeedPlayer);
	SQL_TQuery(db, SQLQueryTSWiew, query, GetClientUserId(client));
}
public SQLQueryTSWiew(Handle:owner, Handle:hndl, const String:error[], any:data) {
	new client;
	if((client = GetClientOfUserId(data))==0) {
		return;
	}
	if(hndl==INVALID_HANDLE) {
		LogError("Query failed: %s", error);
	}
	RankSpeed = SQL_GetRowCount(hndl) + 1;
	decl String:buffer[80];
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "Speed stats:");
	Format(buffer, sizeof(buffer), "► Speed: %i", SpeedPlayer);
	DrawPanelText(panel, buffer);
	Format(buffer, sizeof(buffer), "► Deflect: %i", DeflectPlayer);
	DrawPanelText(panel, buffer);
	Format(buffer, sizeof(buffer), "► Sum Deflect: %i", SumDeflectPlayer);
	DrawPanelText(panel, buffer);
	DrawPanelItem(panel, "Close");
	SendPanelToClient(panel, client, PanelHandlerNothing, 15);
	PrintToChatAll("\x073EFF3E%s\x01 is Top speed \x073EFF3E#%i\x01 out of \x073EFF3E%i\x01 Players with \x073EFF3E%i\x01 Speed!", NamePlayer, RankSpeed, totalCount, SpeedPlayer);
	CloseHandle(panel);
}
public SQLQueryTop10(Handle:owner, Handle:hndl, const String:error[], any:data) {
	new client;
	if((client = GetClientOfUserId(data))==0) {
		return;
	}
	if(hndl==INVALID_HANDLE) {
		LogError("Query failed: %s", error);
	} 
	else {
		new i = 1;
		decl String:PlayerName[40], String:PlayerID[40], String:menuline[40];
		new Handle:menu = CreateMenu(TopMenuHandler1);
		while (SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl,0, PlayerName , 40);
			SQL_FetchString(hndl,1, PlayerID , 40);
			Format(menuline, sizeof(menuline), "%i. %s", i, PlayerName);
			AddMenuItem(menu, PlayerID, menuline);
			i++;
		}
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, 60);
	}
}
public TopMenuHandler1(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:info[40], String:buffer[160];
		GetMenuItem(menu, param2, info, sizeof(info));
		Format(buffer, sizeof(buffer), "SELECT name,rating,kills,deaths,speed,deflect,sumdeflect,playtime FROM stats WHERE steamid='%s'", info);
		SQL_TQuery(db, SQLQueryRankCheck, buffer, GetClientUserId(param1));
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
public SQLQueryRankCheck(Handle:owner, Handle:hndl, const String:error[], any:data) {
	new client;
	if((client = GetClientOfUserId(data))==0) {
		return;
	}
	if(hndl==INVALID_HANDLE) {
		LogError("Query failed: %s", error);
	} else {
		if(!SQL_MoreRows(hndl)){
			PrintToChat(client, "The target was not found.");
			return;
		}
		while(SQL_FetchRow(hndl)) {
			SQL_FetchString(hndl, 0, NamePlayer, 40);
			pointcountPlayer = SQL_FetchInt(hndl, 1);
			killPlayer = SQL_FetchInt(hndl, 2);
			deathPlayer = SQL_FetchInt(hndl, 3);
			SpeedPlayer = SQL_FetchInt(hndl, 4);
			DeflectPlayer = SQL_FetchInt(hndl, 5);
			SumDeflectPlayer = SQL_FetchInt(hndl, 6);
			playtimePlayer = SQL_FetchInt(hndl, 7);
		}
	}
	decl String:query[80];
	Format(query, sizeof(query), "SELECT * FROM stats WHERE rating>'%i'", pointcountPlayer);
	SQL_TQuery(db, SQLQueryRankWiew, query, GetClientUserId(client));
}
public SQLQueryRankWiew(Handle:owner, Handle:hndl, const String:error[], any:data) {
	new client;
	if((client = GetClientOfUserId(data))==0) {
		return;
	}
	if(hndl==INVALID_HANDLE) {
		LogError("Query failed: %s", error);
	}
	ratingPlayer = SQL_GetRowCount(hndl) + 1;
	new Float:kpd = deathPlayer==0?0.0:float(killPlayer)/float(deathPlayer);
	decl String:buffer[80];
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "Ranking stats:");
	Format(buffer, sizeof(buffer), "► Point: %i", pointcountPlayer);
	DrawPanelText(panel, buffer);
	Format(buffer, sizeof(buffer), "► Speed: %i", SpeedPlayer);
	DrawPanelText(panel, buffer);
	Format(buffer, sizeof(buffer), "► Deflect: %i", DeflectPlayer);
	DrawPanelText(panel, buffer);
	Format(buffer, sizeof(buffer), "► Sum Deflect: %i", SumDeflectPlayer);
	DrawPanelText(panel, buffer);
	Format(buffer, sizeof(buffer), "► Rank: %i (of %i)", ratingPlayer, totalCount);
	DrawPanelText(panel, buffer);
	Format(buffer, sizeof(buffer), "► Kills: %i", killPlayer);
	DrawPanelText(panel, buffer);
	Format(buffer, sizeof(buffer), "► Deaths: %i", deathPlayer);
	DrawPanelText(panel, buffer);
	Format(buffer, sizeof(buffer), "► PLAYTIME: %i min", playtimePlayer);
	DrawPanelText(panel, buffer);
	Format(buffer, sizeof(buffer), "► KPD: %.2f", kpd);
	DrawPanelText(panel, buffer);
	DrawPanelItem(panel, "Close");
	SendPanelToClient(panel, client, PanelHandlerNothing, 15);
	PrintToChatAll("\x073EFF3E%s\x01 is Ranked \x073EFF3E#%i\x01 out of \x073EFF3E%i\x01 Players with \x073EFF3E%i\x01 Points!", NamePlayer, ratingPlayer, totalCount, pointcountPlayer);
	CloseHandle(panel);
}
public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data) {
	if(!StrEqual("", error)) {
		LogError("Query failed: %s", error);
	}
}
public Action:Event_player_death(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(client!=0 && attacker!=0) {
		if(!IsFakeClient(client)&&!IsFakeClient(attacker)&&client!=attacker) {
			decl String:clientid[60], String:attackerid[60], String:query[256];
			GetClientAuthId(client, AuthId_Steam2, clientid, sizeof(clientid));
			GetClientAuthId(attacker, AuthId_Steam2, attackerid, sizeof(attackerid));
			new add_point_attacker = (rating[client]+1)/(rating[attacker]+1) + GetRandomInt(1, 3);
			if(add_point_attacker > 10)
				add_point_attacker = GetRandomInt(10, 12);
			new dec_point_client = (rating[client]+1)/(rating[attacker]+1) + GetRandomInt(1, 2);
			if(dec_point_client > 8)
				dec_point_client = GetRandomInt(8, 10);
			rating[client] = rating[client] - 3 - dec_point_client;
			rating[attacker] = rating[attacker] + 5 + add_point_attacker;
			sessionrating[client] = sessionrating[client] - 3 - dec_point_client;
			sessionrating[attacker] = sessionrating[attacker] + 5 + add_point_attacker;
			kills[attacker]++;
			deaths[client]++;
			sessionkills[attacker]++;
			sessiondeaths[client]++;
			Format(query, sizeof(query), "UPDATE stats SET rating='%i',deaths='%i' WHERE steamid='%s'", rating[client], deaths[client], clientid);
			SQL_TQuery(db, SQLErrorCheckCallback, query);
			Format(query, sizeof(query), "UPDATE stats SET rating='%i',kills='%i' WHERE steamid='%s'", rating[attacker], kills[attacker], attackerid);
			SQL_TQuery(db, SQLErrorCheckCallback, query);
		}
	}
}
public Action:Command_say(client, args) {
	if (!client) return Plugin_Continue;
	if (client <= 0) return Plugin_Continue;
	decl String:text[192];
	if(GetCmdArgString(text, sizeof(text))<1) {
		return Plugin_Continue;
	}
	new startidx;
	if(text[strlen(text)-1]=='"') {
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	decl String:clientid[60];
	GetClientAuthId(client, AuthId_Steam2, clientid, sizeof(clientid));
	if(strcmp(text[startidx], "rank", false)==0 || strcmp(text[startidx], "!rank", false)==0 || strcmp(text[startidx], "session", false)==0 || strcmp(text[startidx], "/session", false)==0) {
		if(StrContains(text[startidx], "rank", false)!=-1) {
			decl String:query[160];
			Format(query, sizeof(query), "SELECT name,rating,kills,deaths,speed,deflect,sumdeflect,playtime FROM stats WHERE steamid='%s'", clientid);
			SQL_TQuery(db, SQLQueryRankCheck, query, GetClientUserId(client));
			return Plugin_Handled;
		} else {
			decl String:buffer[80];
			new Handle:panel = CreatePanel();
			SetPanelTitle(panel, "Session stats:");
			Format(buffer, sizeof(buffer), "► Rating: %i", sessionrating[client]);
			DrawPanelText(panel, buffer);
			Format(buffer, sizeof(buffer), "► Kills: %i", sessionkills[client]);
			DrawPanelText(panel, buffer);
			Format(buffer, sizeof(buffer), "► Deaths: %i", sessiondeaths[client]);
			DrawPanelText(panel, buffer);
			Format(buffer, sizeof(buffer), "► PLAYTIME: %i min", sessionplaytime[client]);
			DrawPanelText(panel, buffer);
			DrawPanelItem(panel, "Close");
			SendPanelToClient(panel, client, PanelHandlerNothing, 15);
			CloseHandle(panel);
		}
		return Plugin_Handled;
	} else if(strcmp(text[startidx], "top10", false)==0 || strcmp(text[startidx], "!top10", false)==0 || strcmp(text[startidx], "top", false)==0 || strcmp(text[startidx], "!top", false)==0) {
		SQL_TQuery(db, SQLQueryTop10, "SELECT name,steamid FROM stats ORDER BY rating DESC LIMIT 0,100", GetClientUserId(client));
		return Plugin_Handled;
	} else if (strcmp(text[startidx], "ts", false)==0 || strcmp(text[startidx], "!ts", false)==0 || strcmp(text[startidx], "/ts", false)==0)
	{
		SQL_TQuery(db, SQLQueryTS, "SELECT name,steamid FROM stats ORDER BY speed DESC LIMIT 0,100", GetClientUserId(client));
		return Plugin_Handled;
	} else if (strcmp(text[startidx], "tc", false)==0 || strcmp(text[startidx], "!tc", false)==0 || strcmp(text[startidx], "/tc", false)==0)
	{
		decl String:query[160];
		Format(query, sizeof(query), "SELECT name,speed,deflect,sumdeflect FROM stats WHERE steamid='%s'", clientid);
		SQL_TQuery(db, SQLQueryTSCheck, query, GetClientUserId(client));
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public PanelHandlerNothing(Handle:menu, MenuAction:action, param1, param2) {
	// Do nothing
}