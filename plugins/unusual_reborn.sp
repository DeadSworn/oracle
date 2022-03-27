#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <morecolors>
#include <tf2items>
#include <tf2idb>
#include <donator>


#define PLUGIN_NAME         "Unusual"
#define PLUGIN_AUTHOR       "Erreur 500"
#define PLUGIN_DESCRIPTION	"Add Unusual effects on your weapons"
#define PLUGIN_VERSION      "2.13"
#define PLUGIN_CONTACT      "erreur500@hotmail.fr"
#define EFFECTSFILE			"unusual_list.cfg"
#define PERMISSIONFILE		"unusual_permissions.cfg"
#define DATAFILE			"unusual_effects.txt"
#define WEBSITE 			"http://bit.ly/1aYK7zo"



new String:ClientSteamID[MAXPLAYERS+1][60];
new String:UnusualEffect[PLATFORM_MAX_PATH];
new String:EffectsList[PLATFORM_MAX_PATH];
new String:PermissionsFile[PLATFORM_MAX_PATH];
new ClientItems[MAXPLAYERS+1];

new bool:FirstControl[MAXPLAYERS+1] = {false, ...};

new Permission[22] 					= {0, ...};
new FlagsList[21] 					= {ADMFLAG_RESERVATION, ADMFLAG_GENERIC, ADMFLAG_KICK, ADMFLAG_BAN, ADMFLAG_UNBAN, ADMFLAG_SLAY, ADMFLAG_CHANGEMAP, ADMFLAG_CONVARS, ADMFLAG_CONFIG, ADMFLAG_CHAT, ADMFLAG_VOTE, ADMFLAG_PASSWORD, ADMFLAG_RCON, ADMFLAG_CHEATS, ADMFLAG_CUSTOM1, ADMFLAG_CUSTOM2, ADMFLAG_CUSTOM3, ADMFLAG_CUSTOM4, ADMFLAG_CUSTOM5, ADMFLAG_CUSTOM6, ADMFLAG_ROOT};

new Handle:c_Control				= INVALID_HANDLE;
new Handle:g_hItem 					= INVALID_HANDLE;



public Plugin:myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_CONTACT
};

public OnPluginStart()
{	
	CreateConVar("unusual_version", PLUGIN_VERSION, "Unusual version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	c_Control	= CreateConVar("unusual_controlmod", 	"1", "0 = no control, 1 = event spawn, 2 = event inventory");	
		
	
	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Pre);
	HookEvent("post_inventory_application", EventPlayerInventory, EventHookMode_Post);
	
	//RegConsoleCmd("unusual", OpenMenu, "Get unusual effect on your weapons");
	RegAdminCmd("unusual_control", ControlPlayer, ADMFLAG_GENERIC);
	RegAdminCmd("unusual_permissions", reloadPermissions, ADMFLAG_GENERIC);
	
	LoadTranslations("unusual.phrases"); 
	AutoExecConfig(true, "unsual_configs");
	BuildPath(Path_SM, EffectsList, sizeof(EffectsList), "configs/%s", EFFECTSFILE);
	BuildPath(Path_SM, UnusualEffect,sizeof(UnusualEffect),"configs/%s", DATAFILE);
	BuildPath(Path_SM, PermissionsFile,sizeof(PermissionsFile),"configs/%s", PERMISSIONFILE);

	g_hItem = TF2Items_CreateItem(OVERRIDE_ATTRIBUTES | PRESERVE_ATTRIBUTES);
	TF2Items_SetNumAttributes(g_hItem, 1);
}
public OnAllPluginsLoaded()
{
	if(!LibraryExists("donator.core")) SetFailState("Unabled to find plugin: Basic Donator Interface");
	Donator_RegisterMenuItem("Set Unusual", ChangeUnusualCallBack);
	//Donator_RegisterMenuItem("Change Sprite", SpriteControlCallback);
}
public OnMapStart() 
{
	if(LoadPermissions())
		LogMessage("Unusual effects permissions loaded !");
	else
		LogMessage("Error while charging permissions !");
}

//--------------------------------------------------------------------------------------
//							Control
//--------------------------------------------------------------------------------------

stock bool:IsValidClient(iClient)
{
	if (iClient <= 0) return false;
	if (iClient > MaxClients) return false;
	return IsClientInGame(iClient);
}

//public Action:OpenMenu(iClient, Args)
//{	
//	FirstMenu(iClient);
//}

public Action:ControlPlayer(iClient, Args)
{	
	for(new i=1; i<MaxClients; i++)
		if(IsClientInGame(i))
			Updating(i);
	
	if(IsValidClient(iClient))
		PrintToChat(iClient,"All Players have been controlled !");
	else
		LogMessage("All Players have been controlled !");
}

public Action:reloadPermissions(iClient, Args)
{
	if(LoadPermissions())
	{
		if(IsValidClient(iClient))
			PrintToChat(iClient,"Unusual effects permissions reloaded !");
		else
			LogMessage("Unusual effects permissions reloaded !");
	}
	else
	{
		if(IsValidClient(iClient))
			PrintToChat(iClient,"Error while recharging permissions !");
		else
			LogMessage("Error while recharging permissions !");
	}
}

bool:LoadPermissions()
{
	new Handle: kv;
	kv = CreateKeyValues("Unusual_permissions");
	if(!FileToKeyValues(kv, PermissionsFile))
	{
		LogError("Can't open %s file",PERMISSIONFILE);
		CloseHandle(kv);
		return false;
	}

	KvGotoFirstSubKey(kv, true);
	Permission[0]  = KvGetNum(kv, "0", 0);
	Permission[1]  = KvGetNum(kv, "a", 0);
	Permission[2]  = KvGetNum(kv, "b", 0);
	Permission[3]  = KvGetNum(kv, "c", 0);
	Permission[4]  = KvGetNum(kv, "d", 0);
	Permission[5]  = KvGetNum(kv, "e", 0);
	Permission[6]  = KvGetNum(kv, "f", 0);
	Permission[7]  = KvGetNum(kv, "g", 0);
	Permission[8]  = KvGetNum(kv, "h", 0);
	Permission[9]  = KvGetNum(kv, "i", 0);
	Permission[10] = KvGetNum(kv, "j", 0);
	Permission[11] = KvGetNum(kv, "k", 0);
	Permission[12] = KvGetNum(kv, "l", 0);
	Permission[13] = KvGetNum(kv, "m", 0);
	Permission[14] = KvGetNum(kv, "n", 0);
	Permission[15] = KvGetNum(kv, "o", 0);
	Permission[16] = KvGetNum(kv, "p", 0);
	Permission[17] = KvGetNum(kv, "q", 0);
	Permission[18] = KvGetNum(kv, "r", 0);
	Permission[19] = KvGetNum(kv, "s", 0);
	Permission[20] = KvGetNum(kv, "t", 0);
	Permission[21] = KvGetNum(kv, "z", 0);
	CloseHandle(kv);
	return true;
}

bool:isAuthorized(Handle:kv, iClient, bool:Strict)
{
	new Count;
	new Limit = GetLimit(GetUserFlagBits(iClient));
	
	KvRewind(kv);
	if(Limit == -1)
		return true;
		
	if(!KvJumpToKey(kv, ClientSteamID[iClient], false))
	{
		Count = 0;
	}
	else
	{
		if(!KvGotoFirstSubKey(kv, true))
		{
			LogError("Invalid file : %s",DATAFILE);
			return false;
		}
		Count++;
			
		while(KvGotoNextKey(kv, true))
			Count++;
	}
	
	if(Strict && Count < Limit)
		return true;
	else if(!Strict && Count <= Limit)
		return true;
	else
		return true;
}

GetLimit(flags)
{
	new Limit 	= 0;
	new i 		= 0;
	
	if(flags == 0)
		return Limit;
		
	do
	{
		if( (flags & FlagsList[i]) && ((Limit < Permission[i+1]) || (Permission[i+1] == -1)) )
			Limit = Permission[i+1];
		i++;
	}while(Limit != -1 && i<21)
	return Limit;
}

//--------------------------------------------------------------------------------------
//							Update Effects
//--------------------------------------------------------------------------------------


public Action:EventPlayerSpawn(Handle:hEvent, const String:strName[], bool:bHidden)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(!IsValidClient(iClient)) return Plugin_Continue;
	if(IsFakeClient(iClient))	return Plugin_Continue;
	if(GetConVarInt(c_Control) == 1 || !FirstControl[iClient])
	{
		Updating(iClient);
		if(GetClientTeam(iClient) == 2 || GetClientTeam(iClient) == 3)
			UpdateWeapon(iClient);	
		if(!FirstControl[iClient])
			FirstControl[iClient] = true;
	}
	return Plugin_Continue;
}

public Action:EventPlayerInventory(Handle:hEvent, const String:strName[], bool:bHidden)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(GetConVarInt(c_Control) == 2)
	{
		if (!IsValidClient(iClient)) return Plugin_Continue;
		if (!IsPlayerAlive(iClient)) return Plugin_Continue;
		Updating(iClient);
	}
	return Plugin_Continue;
}

Updating(iClient)
{
	new Handle: kv;
	kv = CreateKeyValues("Unusual_effects");
	if(!FileToKeyValues(kv, UnusualEffect))
	{
		LogError("Can't open %s file",DATAFILE);
		CloseHandle(kv);
		return;
	}
	
	//LogMessage("Controle en cours !!");
		
	if(isAuthorized(kv, iClient, false))
	{
		CloseHandle(kv);
		return;
	}
	
	CPrintToChat(iClient, "%t","Sent6");
	DeleteDatas(kv, iClient);
	
	KvRewind(kv);
	if(!KeyValuesToFile(kv, UnusualEffect))
		LogError("Can't save %s file modifications",DATAFILE);
	CloseHandle(kv);
}

DeleteDatas(Handle:kv, iClient)
{
	new String:PlayerInfo[60];
	
	KvRewind(kv);
	GetClientAuthId(iClient, AuthId_Steam2, PlayerInfo, sizeof(PlayerInfo));
	
	if(!KvJumpToKey(kv, PlayerInfo))
		return;
		
	new String:section[7];
	while(KvGotoFirstSubKey(kv, true))
	{
		KvGetSectionName(kv, section, sizeof(section)); 
		KvGoBack(kv);
		KvDeleteKey(kv, section);
	}
	return;
}

public Action:TF2Items_OnGiveNamedItem(iClient, String:classname[], iItemDefinitionIndex, &Handle:hItem)
{
	if(!IsValidClient(iClient)) return Plugin_Continue;
	if(IsFakeClient(iClient))	return Plugin_Continue;
	new Handle: kv;
	new String:PlayerInfo[60];	
	new String:str_iItemDefinitionIndex[10];
	new Float:fltEffect;
	new Effect;
		
	kv = CreateKeyValues("Unusual_effects");
	if(!FileToKeyValues(kv, UnusualEffect))
	{
		LogMessage("Can't open %s file",DATAFILE);
		CloseHandle(kv);
		return Plugin_Continue;
	}
	GetClientAuthId(iClient, AuthId_Steam2, PlayerInfo, sizeof(PlayerInfo));
	if(!KvJumpToKey(kv, PlayerInfo, false))
	{
		CloseHandle(kv);
		return Plugin_Continue;
	}
	IntToString(iItemDefinitionIndex, str_iItemDefinitionIndex, sizeof(str_iItemDefinitionIndex));
	if(!KvJumpToKey(kv, str_iItemDefinitionIndex, false))
	{
		CloseHandle(kv);
		return Plugin_Continue;
	}
	Effect = KvGetNum(kv, "effect", -1);
	if(Effect == -1)
	{
		LogMessage("Invalid effect for %s weapon %i",PlayerInfo, iItemDefinitionIndex);
		CloseHandle(kv);
		return Plugin_Continue;
	}
	fltEffect = Effect * 1.0;
	CloseHandle(kv);
	
	TF2Items_SetAttribute(g_hItem, 0, 134, fltEffect);
	hItem = g_hItem;
	//LogMessage("WEAPON %i, with %i for %i",iItemDefinitionIndex,Effect,iClient);
	return Plugin_Changed;
}
UpdateWeapon(iClient)
{
	new ent = -1;
	new prev = -1;
	while ((ent = FindEntityByClassname(ent, "tf_wearable")) != -1  && IsValidEntity(ent)) 
	{
		new owner = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity"); 
		if (owner == iClient)
		{
			if (prev && IsValidEdict(prev))
			{
				RemovePlayerItem(iClient, prev);
				RemoveEdict(prev);
			}
			prev = ent;
		}
	}
	if (prev && IsValidEdict(prev))
	{
		RemovePlayerItem(iClient, prev);
		RemoveEdict(prev);
	}
	TF2_RegeneratePlayer(iClient);
	new primary = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Primary);
	TF2_RegeneratePlayer(iClient);
	EquipPlayerWeapon(iClient, primary);
}
//--------------------------------------------------------------------------------------
//							Menu selection
//--------------------------------------------------------------------------------------
public DonatorMenu:ChangeUnusualCallBack(iClient) FirstMenu(iClient);	
FirstMenu(iClient)
{	
	if(IsValidClient(iClient))
	{
		new String:PlayerInfo[60];
		new Handle:Menu1 = CreateMenu(Menu1_1);
		SetMenuTitle(Menu1, "What do you want ?");
		AddMenuItem(Menu1, "0", "Add effect");
		AddMenuItem(Menu1, "1", "Delete effects");
		AddMenuItem(Menu1, "2", "Show effects");

		GetClientAuthId(iClient, AuthId_Steam2, PlayerInfo, sizeof(PlayerInfo));
		strcopy(ClientSteamID[iClient], 60, PlayerInfo);
		
		SetMenuExitButton(Menu1, true);
		DisplayMenu(Menu1, iClient, MENU_TIME_FOREVER);
	}
}

public Menu1_1(Handle:menu, MenuAction:action, iClient, args)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		if(args == 0)
			if(GetClientTeam(iClient) == 2 || GetClientTeam(iClient) == 3)
				QualityMenu(iClient);
			else
				CPrintToChat(iClient, "%t","Sent2");
		else if(args == 1)
			DeleteWeapPanel(iClient);
		else if(args == 2)
		{
			FirstMenu(iClient);
			ShowMOTDPanel(iClient, "Unusual effects", WEBSITE, MOTDPANEL_TYPE_URL );
		}
	}
}

//--------------------------------------------------------------------------------------
//							Remove Effect
//--------------------------------------------------------------------------------------

DeleteWeapPanel(iClient)
{
	new Handle: kv;
	kv = CreateKeyValues("Unusual_effects");
	new String:section[7];
	new String:ItemsName[64];
	new Handle:YourItemsMenu = CreateMenu(YourItemsMenuAnswer);
		
	SetMenuTitle(YourItemsMenu, "What items ?");
	FileToKeyValues(kv, UnusualEffect);
		
	if(!KvJumpToKey(kv, ClientSteamID[iClient], false))
	{
		CPrintToChat(iClient, "%t","Sent3");
		CloseHandle(kv);
		return;
	}
		
	if(!KvGotoFirstSubKey(kv, true))
	{
		LogError("Invalid file : %s",DATAFILE);
		CloseHandle(kv);
		return;
	}
	KvGetSectionName(kv, section, sizeof(section));
	new SectionID = StringToInt(section); 
	TF2IDB_GetItemName(SectionID, ItemsName, sizeof(ItemsName));
	AddMenuItem(YourItemsMenu, section, ItemsName);
			
	while(KvGotoNextKey(kv, true))
	{	
		KvGetSectionName(kv, section, sizeof(section)); 
		SectionID = StringToInt(section); 
		TF2IDB_GetItemName(SectionID, ItemsName, sizeof(ItemsName));
		AddMenuItem(YourItemsMenu, section, ItemsName);
	}
	CloseHandle(kv);
	SetMenuExitButton(YourItemsMenu, true);
	DisplayMenu(YourItemsMenu, iClient, MENU_TIME_FOREVER);
}
public YourItemsMenuAnswer(Handle:menu, MenuAction:action, iClient, args)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		new String:WeapID[7];
		new Handle: kv;
		kv = CreateKeyValues("Unusual_effects");
		
		if(!FileToKeyValues(kv, UnusualEffect))
		{
			LogError("Can't open %s",DATAFILE);
			CloseHandle(kv);
			return;
		}
		
		KvJumpToKey(kv, ClientSteamID[iClient], true);
		GetMenuItem(menu, args, WeapID, sizeof(WeapID));
			
		if(KvDeleteKey(kv, WeapID))
		{
			KvRewind(kv);
			if(!KeyValuesToFile(kv, UnusualEffect))
				LogError("Can't save %s modifications",DATAFILE);
			CloseHandle(kv);
			CPrintToChat(iClient, "%t", "Sent4");
			if(GetClientTeam(iClient) == 2 || GetClientTeam(iClient) == 3)
			{
				//UpdateWeapon(iClient);
			}
			DeleteWeapPanel(iClient);
		}
		else
		{
			CPrintToChat(iClient, "%t","Sent5");
			CloseHandle(kv);
		}
	}	
}
//--------------------------------------------------------------------------------------
//							Quality + Effect
//--------------------------------------------------------------------------------------

QualityMenu(iClient)
{
	new Handle: kv;
	kv = CreateKeyValues("Unusual_effects");
	if(!FileToKeyValues(kv, UnusualEffect))
	{
		LogError("Can't open %s file",DATAFILE);
		CloseHandle(kv);
		return;
	}
	if(!isAuthorized(kv, iClient, true))
	{
		CPrintToChat(iClient, "%t", "Sent7");
		CloseHandle(kv);
		return;
	}
	CloseHandle(kv);
	new ent = -1;
	ClientItems[iClient] = -1;
	decl String:szSlotName[64];
	while ((ent = FindEntityByClassname(ent, "tf_wearable" )) != -1) 
	{ 
		new owner = GetEntPropEnt( ent, Prop_Send, "m_hOwnerEntity" ); 
		new itemDef = GetEntProp( ent, Prop_Send, "m_iItemDefinitionIndex" ); 
		if (owner == iClient)
		{
			TF2IDB_GetItemSlotName(itemDef, szSlotName, sizeof(szSlotName));
			if(StrEqual(szSlotName, "head", false))
			{
				ClientItems[iClient] = itemDef;
			}	
		}
	}
	if(ClientItems[iClient] == -1){
		FirstMenu(iClient);
		CPrintToChat(iClient, "{Purple}[Unusual] {default} Item invalid !")
	}
	else if(ClientItems[iClient] != -1)
		PanelEffect(iClient);
}
PanelEffect(iClient)
{
	new String:EffectID[8];
	new String:EffectName[128];

	new Handle:UnusualMenu = CreateMenu(UnusualMenuAnswer);
	SetMenuTitle(UnusualMenu, "Select Unusual effect :");
	AddMenuItem(UnusualMenu, "0", "Show effects");
	new Handle:kv;
	kv = CreateKeyValues("Unusual_effects");
	if(!FileToKeyValues(kv, EffectsList))
	{
		LogError("[UNUSUAL] Could not open file %s", EFFECTSFILE);
		CloseHandle(kv);
		return;
	}
	
	if(!KvGotoFirstSubKey(kv, true)) // First UE
	{
		LogMessage("ERROR: Can't find unusual effects in %s", EFFECTSFILE);
		CloseHandle(kv);
		return;
	}
	
	do
	{
		KvGetSectionName(kv, EffectID, sizeof(EffectID));
		KvGetString(kv, "name", EffectName, sizeof(EffectName));
		AddMenuItem(UnusualMenu, EffectID, EffectName);
	}
	while(KvGotoNextKey(kv, true))
	
	CloseHandle(kv);
	SetMenuExitButton(UnusualMenu, true);
	DisplayMenu(UnusualMenu, iClient, MENU_TIME_FOREVER);
}

public UnusualMenuAnswer(Handle:menu, MenuAction:action, iClient, args)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		if(args == 0)
		{
			PanelEffect(iClient);
			ShowMOTDPanel(iClient, "Unusual effects", WEBSITE, MOTDPANEL_TYPE_URL );
		}
		
		new String:Effect[3];
		new String:strName[5];
		new Handle: kv;
		
		GetMenuItem(menu, args, Effect, sizeof(Effect));
		kv = CreateKeyValues("Unusual_effects");
		if(!FileToKeyValues(kv, UnusualEffect))
		{
			LogError("Can't open %s file",DATAFILE);
			CloseHandle(kv);
			return;
		}
		KvJumpToKey(kv, ClientSteamID[iClient], true);
		
		Format(strName, sizeof(strName), "%d",ClientItems[iClient]);
		
		KvJumpToKey(kv, strName, true);
		KvSetString(kv, "effect", Effect);
		KvRewind(kv);
		if(!KeyValuesToFile(kv, UnusualEffect))
			LogError("Can't save %s file modifications",DATAFILE);
		CloseHandle(kv);
		if(GetClientTeam(iClient) == 2 || GetClientTeam(iClient) == 3)
		{
			//UpdateWeapon(iClient);
		}
		CPrintToChat(iClient, "%t", "Sent8");
		FirstMenu(iClient); 
	}	
}


