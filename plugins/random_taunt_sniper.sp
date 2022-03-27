#include <sourcemod>
#include <sdktools>
#include <tf2items>
#include <tf2_stocks>
#include <sdkhooks>
new Handle:hPlayTaunt;
new itemdef[MAXPLAYERS+1];
public OnPluginStart()
{
	new Handle:conf = LoadGameConfigFile("tf2.tauntem");
	if (conf == INVALID_HANDLE)
	{
		SetFailState("Unable to load gamedata/tf2.tauntem.txt. Good luck figuring that out.");
		return;
	}
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(conf, SDKConf_Signature, "CTFPlayer::PlayTauntSceneFromItem");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	hPlayTaunt = EndPrepSDKCall();
	if (hPlayTaunt == INVALID_HANDLE)
	{
		SetFailState("Unable to initialize call to CTFPlayer::PlayTauntSceneFromItem. Wait patiently for a fix.");
		CloseHandle(conf);
		return;
	}
	CreateTimer(10.0, Stop_Taunt, _, TIMER_REPEAT);
	CloseHandle(conf);
	AddCommandListener(CheckTaunt, "taunt");
	HookEvent("player_spawn", Event_player_spawn, EventHookMode_Post);
}
public Action:Event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	itemdef[client] = 0;
}
public Action:CheckTaunt(client, const String:command[], argc)
{
	itemdef[client] = Get_Taunt();
	if (itemdef[client] > 0 && IsDontUse(client))
	{
		new ent = MakeCEIVEnt(client, itemdef[client]);
		if (!IsValidEntity(ent))
		{
			ReplyToCommand(client, "[SM] Couldn't create entity for taunt");
			return Plugin_Handled;
		}
		new Address:pEconItemView = GetEntityAddress(ent) + Address:FindSendPropInfo("CTFWearable", "m_Item");
		SDKHook(client, SDKHook_PostThink, OnPostThink);
		SDKCall(hPlayTaunt, client, pEconItemView) ? 1 : 0;
		AcceptEntityInput(ent, "Kill");
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
public OnPostThink(client)
{
	if (IsValidClient(client))
	{
		if (!TF2_IsPlayerInCondition(client, TFCond_Taunting))
		{
			TF2_RemoveCondition(client, TFCond_Taunting);
			itemdef[client] = 0;
			SDKUnhook(client, SDKHook_PostThink, OnPostThink);
		}
	}
}
public Action:Stop_Taunt(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			if (!TF2_IsPlayerInCondition(i, TFCond_Taunting))
			{
				itemdef[i] = 0;
			}
		}
	}
}
stock bool:IsDontUse(client)
{
	new iTarget = GetClientAimTarget(client, true)
	if (!IsValidClient(iTarget)) return true;
	new Float:client_pos[3], Float:target_pos[3];
	GetClientEyePosition(client, client_pos);
	GetClientEyePosition(iTarget, target_pos);
	if (CanSeeTarget(client_pos, target_pos, 3.0))
	{
		switch (itemdef[iTarget])
		{
			case 167, 1106, 1107, 1110, 1111, 1118:
				return false;
		}
		if(GetClientTeam(client) != GetClientTeam(iTarget)) return false;
	}
	return true;
}
stock bool:CanSeeTarget(Float:pos[3], Float:targetPos[3], Float:range)
{
	new Float:fDistance;
	fDistance = GetVectorDistanceMeter(pos, targetPos);
	if (fDistance <= range)
	{
		return true;
	}
	return false;
}
stock Float:GetVectorDistanceMeter(const Float:vec1[3], const Float:vec2[3], bool:squared=false) 
{
	return UnitToMeter(GetVectorDistance(vec1, vec2, squared));
}
stock Float:UnitToMeter(Float:distance)
{
	return distance / 50.00;
}
stock Get_Taunt()
{
	new select_taunt = GetRandomInt(1, 10);
	switch (select_taunt)
	{
		case 1:
		{
			return 167;
		}
		case 2:
		{
			return 438;
		}
		case 3:
		{
			return 463;
		}
		case 4:
		{
			return 1118;
		}
		case 5:
		{
			return 1015;
		}
		case 6:
		{
			return 1106;
		}
		case 7:
		{
			return 1107;
		}
		case 8:
		{
			return 1110;
		}
		case 9:
		{
			return 1111;
		}
		case 10:
		{
			return 1116;
		}
		default:
		{
			return 0;
		}
	}
	return 0;
}
stock MakeCEIVEnt(client, itemdefS)
{
	static Handle:hItem;
	if (hItem == INVALID_HANDLE)
	{
		hItem = TF2Items_CreateItem(OVERRIDE_ALL|PRESERVE_ATTRIBUTES|FORCE_GENERATION);
		TF2Items_SetClassname(hItem, "tf_wearable_vm");
		TF2Items_SetQuality(hItem, 6);
		TF2Items_SetLevel(hItem, 1);
		TF2Items_SetNumAttributes(hItem, 0);
	}
	TF2Items_SetItemIndex(hItem, itemdefS);
	return TF2Items_GiveNamedItem(client, hItem);
}
stock bool:IsValidClient(iClient)
{
	if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return false;
	return true;
}