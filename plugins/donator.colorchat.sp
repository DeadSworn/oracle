#include <sourcemod>
#include <colors>
#include <clientprefs>
#include <loghelper>
#include <donator>
#include <basecomm>

#pragma semicolon 1

enum
{
 	cNone = 0,
	cTeamColor,
	cGreen,
	cOlive,
	cAqua,
	cAxis,
	cAzure,
	cBlueViolet,
	cBrown,
	cChocolate,
	cCoral,
	cCrimson,
	cDarkmagneta,
	cDarkorange,
	cFullred,
	cGold,
	cGray,
	cHaunted,
	cFuchsia,
	cMaroon,
	cOrange,
	cOrangered,
	cPurle,
	cRandom,
	cMax
};

new String:szColorCodes[][] = {
	"\x01", 
	"\x03", 
	"\x04", 
	"\x05", 
	"\x0700FFFF", 
	"\x07FF4040", 
	"\x07007FFF", 
	"\x078A2BE2", 
	"\x07A52A2A", 
	"\x07D2691E", 
	"\x07FF7F50", 
	"\x07DC143C", 
	"\x078B008B", 
	"\x07FF8C00", 
	"\x07FF0000", 
	"\x07FFD700",
	"\x07CCCCCC",
	"\x0738F3AB",
	"\x07FF00FF",
	"\x07800000",
	"\x07FFA500",
	"\x07FF4500",
	"\x07800080"
};

new const String:szColorNames[cMax][] = {
	"None",
	"Team Color",
	"Green",
	"Olive",
	"Aqua",
	"Axis",
	"Azure",
	"Blue Violet",
	"Brown",
	"Chocolate",
	"Coral",
	"Crimson",
	"Dark Magenta",
	"Dark Orange",
	"Fullred",
	"Gold",
	"Gray",
	"Haunted",
	"Fuchsia",
	"Maroon",
	"Orange",
	"Orange red",
	"Purple",
	"Random"
};

new g_iColor[MAXPLAYERS + 1];
new g_iColorName[MAXPLAYERS + 1];
new bool:g_bIsInterval[MAXPLAYERS + 1];
new Handle:g_hColorCookie = INVALID_HANDLE;
new Handle:g_hColorNameCookie = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Donator: Colored Chat",
	author = "Nut",
	description = "Donators get colored chat!",
	version = "0.4",
	url = ""
}

public OnPluginStart()
{
	AddCommandListener(SayCallback, "say");
	AddCommandListener(SayCallback, "say_team");
	
	g_hColorCookie = RegClientCookie("donator_colorcookie", "Chat color for donators.", CookieAccess_Private);
	g_hColorNameCookie = RegClientCookie("donator_colornamecookie", "Chat color for donators.", CookieAccess_Private);
}

public OnAllPluginsLoaded()
{
	if(!LibraryExists("donator.core")) SetFailState("Unabled to find plugin: Basic Donator Interface");
	Donator_RegisterMenuItem("Set Chat Color", ChatColorCallback);
	Donator_RegisterMenuItem("Set Name Color", NameColorCallback);
}

public OnPostDonatorCheck(iClient)
{
	if (!IsClientInGame(iClient)) return;
	g_iColor[iClient] = cNone;
	g_iColorName[iClient] = cNone;

	if (AreClientCookiesCached(iClient))
	{
		new String:szBuffer[24];
		new String:szBufferName[24];
		GetClientCookie(iClient, g_hColorCookie, szBuffer, sizeof(szBuffer));
		GetClientCookie(iClient, g_hColorNameCookie, szBufferName, sizeof(szBufferName));

		if (strlen(szBuffer) > 0)
			g_iColor[iClient] = StringToInt(szBuffer);
		if (strlen(szBufferName) > 0)
			g_iColorName[iClient] = StringToInt(szBufferName);
	}
}

public OnClientDisconnect(iClient)
{
	g_iColor[iClient] = cNone;
	g_iColorName[iClient] = cNone;
}

public Action:SayCallback(iClient, const String:szCommand[], iArgc)
{
	if (!iClient) return Plugin_Continue;
	if (iClient <= 0) return Plugin_Continue;
	if(!IsClientInGame(iClient)) return Plugin_Continue;
	if (g_bIsInterval[iClient])
	{
		return Plugin_Handled;
	}
	
	decl String:szArg[255], String:szChatMsg[255];
	GetCmdArgString(szArg, sizeof(szArg));

	StripQuotes(szArg);
	TrimString(szArg);

	if(szArg[0] == '/' || szArg[0] == '!' || szArg[0] == '@' || BaseComm_IsClientGagged(iClient) 
	|| StrEqual(szArg, "timeleft", false) || StrEqual(szArg, "nextmap", false) || StrEqual(szArg, "ff", false) 
	|| StrEqual(szArg, "motd", false) || StrEqual(szArg, "currentmap", false) 
	|| StrEqual(szArg, "top", false) || StrEqual(szArg, "rank", false) || StrEqual(szArg, "session", false)
	|| StrEqual(szArg, "top10", false) || StrEqual(szArg, "rtd", false) || StrEqual(szArg, "thetime", false))	return Plugin_Continue;
	new iColor = g_iColor[iClient];
	new iColorName = g_iColorName[iClient];
	decl String:teamclient[18] = "";
	if(GetClientTeam(iClient) == 1)
		teamclient = "\x07CCCCCC*SPEC* ";
	if (!iColor)
		iColor = cNone;
	if (!iColorName)
		iColorName = cTeamColor;	

	if (iColor == cRandom)
		iColor = GetRandomInt(cNone+1, cRandom-1);
	if (iColorName == cRandom)
		iColorName = GetRandomInt(cNone+1, cRandom-1); 
	if (strlen(szArg) <= 0)
	{
		iColor = cNone;
	}
	PrintToServer("%N: %s", iClient, szArg);
	g_bIsInterval[iClient] = true;
	CreateTimer(0.75, Chat_Interval, iClient);
	if (StrEqual(szCommand, "say", true))
	{
		LogPlayerEvent(iClient, "say", szArg);
		FormatEx(szChatMsg, 255, "%s%s%N\x01 : %s%s", teamclient, szColorCodes[iColorName], iClient, szColorCodes[iColor], szArg);
		CPrintToChatAllEx(iClient, szChatMsg);
	}
	else
	{
		LogPlayerEvent(iClient, "say_team", szArg);
		FormatEx(szChatMsg, 255, "(TEAM) %s%s%N\x01 : %s%s", teamclient, szColorCodes[iColorName], iClient, szColorCodes[iColor], szArg);
		
		new iTeam = GetClientTeam(iClient);
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i)) continue;
			if(iTeam == GetClientTeam(i))
			CPrintToChatEx(i, iClient, szChatMsg);
		}
	}
	return Plugin_Handled;
}
public Action:Chat_Interval(Handle:timer, any:iClient)
{
	g_bIsInterval[iClient] = false;
}
public DonatorMenu:ChatColorCallback(iClient) Panel_SetColor(iClient);

public Panel_SetColor(iClient)
{
	new Handle:hMenu = CreateMenu(SetColorHandler);
	SetMenuTitle(hMenu,"Set Chat Color:");

	decl String:szItem[24];
	for (new i = 0; i < cMax; i++)
	{
		FormatEx(szItem, sizeof(szItem), "%i", i);
		if (g_iColor[iClient] == i)
			AddMenuItem(hMenu, szItem, szColorNames[i], ITEMDRAW_DISABLED);
		else
			AddMenuItem(hMenu, szItem, szColorNames[i], ITEMDRAW_DEFAULT);
	}
	DisplayMenu(hMenu, iClient, 20);
}

public SetColorHandler(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			new iColor = param2;
			
			g_iColor[param1] = iColor;
			
			decl String:szColor[24];
			FormatEx(szColor, sizeof(szColor), "%i", iColor);
			SetClientCookie(param1, g_hColorCookie, szColor);
			if (iColor == cRandom)
				CPrintToChat(param1, "[SM]: Your new chat color is {olive}random{default}.");
			else
				CPrintToChatEx(param1, param1, "[SM]: %sThis is your new chat color.", szColorCodes[param2]);
		}
	}
}

public DonatorMenu:NameColorCallback(iClient) Panel_SetNameColor(iClient);

public Panel_SetNameColor(iClient)
{
	new Handle:hMenu = CreateMenu(SetNameColorHandler);
	SetMenuTitle(hMenu,"Set Name Color:");

	decl String:szItem[24];
	for (new i = 0; i < cMax; i++)
	{
		FormatEx(szItem, sizeof(szItem), "%i", i);
		if (g_iColorName[iClient] == i)
			AddMenuItem(hMenu, szItem, szColorNames[i], ITEMDRAW_DISABLED);
		else
			AddMenuItem(hMenu, szItem, szColorNames[i], ITEMDRAW_DEFAULT);
	}
	DisplayMenu(hMenu, iClient, 20);
}

public SetNameColorHandler(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			new iColorName = param2;
			
			g_iColorName[param1] = iColorName;
			
			decl String:szColor[24];
			FormatEx(szColor, sizeof(szColor), "%i", iColorName);
			SetClientCookie(param1, g_hColorNameCookie, szColor);
			if (iColorName == cRandom)
				CPrintToChat(param1, "[SM]: Your new name color is {olive}random{default}.");
			else
				CPrintToChatEx(param1, param1, "[SM]: %sThis is your new name color.", szColorCodes[param2]);
		}
	}
}