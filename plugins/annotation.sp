#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <morecolors>

#pragma semicolon 1

#define MAX_ANNOTATION_COUNT 50
#define MAX_ANNOTATION_LENGTH 256
#define ANNOTATION_REFRESH_RATE 0.1
#define ANNOTATION_OFFSET 8750

new String:g_AnnotationText[MAX_ANNOTATION_COUNT][MAX_ANNOTATION_LENGTH];
new Float:g_AnnotationPosition[MAX_ANNOTATION_COUNT][3];
new bool:g_AnnotationCanBeSeenByClient[MAX_ANNOTATION_COUNT][MAXPLAYERS+1];
new bool:g_AnnotationEnabled[MAX_ANNOTATION_COUNT];
new bool:g_HasAnnotation[MAXPLAYERS+1];

new g_ViewDistance;

new Handle:g_hCVarViewDist;

public OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerChanged);
	HookEvent("player_death", Event_PlayerDeath);
	
	RegConsoleCmd("sm_tagme", Command_Annotate);
	
	g_hCVarViewDist = CreateConVar("sm_annotate_view_dist", "50", "Sets the maximum distance at which annotations will be sent to players", _, true, 50.0);
	
	g_ViewDistance = RoundFloat(Pow(GetConVarFloat(g_hCVarViewDist), 2.0));
	
	HookConVarChange(g_hCVarViewDist, CB_ViewDistChanged);
}

public CB_ViewDistChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) 
{
	g_ViewDistance = RoundFloat(Pow(StringToFloat(newVal), 2.0));
}

public OnMapStart()
{
	CreateTimer( ANNOTATION_REFRESH_RATE, Timer_RefreshAnnotations, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	for(new i = 0; i < MAX_ANNOTATION_COUNT; i++)
	{
		if(g_AnnotationEnabled[i]) 
			Timer_ExpireAnnotation(INVALID_HANDLE, i);
	}
}

public OnPluginEnd()
{
	for(new i = 0; i < MAX_ANNOTATION_COUNT; i++)
	{
		if(g_AnnotationEnabled[i]) 
			Timer_ExpireAnnotation(INVALID_HANDLE, i);
	}
}

public Action:Event_PlayerDeath(Handle:hEvent, const String:name[], bool:dontbroadcast)
{
	new client = GetEventInt(hEvent, "userid");
	if (g_HasAnnotation[client] == true)
	{
		g_HasAnnotation[client] = false;
	}
	return Plugin_Continue;
}

public Action:Event_PlayerChanged(Handle:event, const String:name[], bool:dontbroadcast)
{
	for(new i = 0; i < MAX_ANNOTATION_COUNT; i++)
	{
		if(!g_AnnotationEnabled[i]) continue;
		for(new client = 1; client < MaxClients; client++)
		{
			if(IsClientInGame(client) && !IsFakeClient(client))
			{        
				new bool:canClientSeeAnnotation = CanPlayerSee(client, i);
				if(!canClientSeeAnnotation && g_AnnotationCanBeSeenByClient[i][client])
				{
					// The player can no longer see the annotation
					HideAnnotationFromPlayer(client, i);
					g_AnnotationCanBeSeenByClient[i][client] = false;
				}
				else if (canClientSeeAnnotation && !g_AnnotationCanBeSeenByClient[i][client])
				{
					ShowAnnotationToPlayer(client, i);
					g_AnnotationCanBeSeenByClient[i][client] = true;
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:Command_Annotate(client, args)
{
	if (GetCmdArgs() < 1)
	{
		PrintToChat(client, "[SM] Usage: sm_tagme <message>");
		return Plugin_Handled;
	}
	
	if (g_HasAnnotation[client] == true)
	{
		return Plugin_Handled;
	}
	
//    if(!SetTeleportEndPoint(client))
//    {
//        PrintToChat(client, "[SM] Could not find spawn point.");
//        return Plugin_Handled;
//    }
	
//    if(NearExistingAnnotation(g_pos))
//    {
//        PrintToChat(client, "[SM] There is already an annotation here!");
//        return Plugin_Handled;
//    }
	
	new annotation_id = GetFreeAnnotationID();
	if(annotation_id == -1)
	{
		PrintToChat(client, "[SM] No free annotations!");
		return Plugin_Handled;
	}
	
	decl String:ArgString[MAX_ANNOTATION_LENGTH];
	
	GetCmdArgString(ArgString, sizeof(ArgString));
	new pos = FindCharInString(ArgString, ' ');
	
	strcopy(g_AnnotationText[annotation_id], sizeof(g_AnnotationText[]), ArgString[pos+1]);
	g_AnnotationEnabled[annotation_id] = true;
//    g_AnnotationPosition[annotation_id] = g_pos;
	
	PrintToChat(client, "[SM] Annotation created.");
	g_HasAnnotation[client] = true;
	
	for(new i=1; i <= MaxClients; i++)
	{
		ShowAnnotationToPlayer(i, annotation_id);
	}
	return Plugin_Handled;
}

public ShowAnnotationToPlayer(client, annotation_id)
{
	new Handle:event = CreateEvent("show_annotation");
	if (event == INVALID_HANDLE) return;
	
//    SetEventFloat(event, "worldPosX", g_AnnotationPosition[annotation_id][0]);
//    SetEventFloat(event, "worldPosY", g_AnnotationPosition[annotation_id][1]);
//    SetEventFloat(event, "worldPosZ", g_AnnotationPosition[annotation_id][2]);
	SetEventFloat(event, "lifetime", 99999.0);
	SetEventInt(event, "id", annotation_id*MAXPLAYERS + client + ANNOTATION_OFFSET);
	SetEventString(event, "text", g_AnnotationText[annotation_id]);
	SetEventInt(event, "follow_entindex", client);
	SetEventString(event, "play_sound", "vo/null.wav");
	SetEventInt(event, "visibilityBitfield", (1 << client));
	FireEvent(event);
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients() || !entity;
}

public bool:CanPlayerSee(client, annotation_id)
{
	decl Float:EyePos[3];
	GetClientEyePosition(client, EyePos); 
	
	if(GetVectorDistance(EyePos, g_AnnotationPosition[annotation_id], true) > g_ViewDistance) return false;

	TR_TraceRayFilter(EyePos, g_AnnotationPosition[annotation_id], MASK_PLAYERSOLID, RayType_EndPoint, TraceEntityFilterPlayer, client);
	if (TR_DidHit(INVALID_HANDLE))
	{
		return false;
	}
	return true;
}

public GetFreeAnnotationID()
{
	for(new i = 0; i < MAX_ANNOTATION_COUNT; i++)
	{
		if(g_AnnotationEnabled[i]) continue;
		return i;
	}
	return -1;
}

public HideAnnotationFromPlayer(client, annotation_id)
{
	new Handle:event = CreateEvent("hide_annotation");
	if (event == INVALID_HANDLE) return;
	
	SetEventInt(event, "id", annotation_id*MAXPLAYERS + client + ANNOTATION_OFFSET);
	FireEvent(event);
}

//TIMERS
public Action:Timer_RefreshAnnotations(Handle:timer, any:entity)
{
	for(new i = 0; i < MAX_ANNOTATION_COUNT; i++)
	{
		if(!g_AnnotationEnabled[i]) continue;
		for(new client = 1; client < MaxClients; client++)
		{
			if(IsClientInGame(client) && !IsFakeClient(client))
			{        
				new bool:canClientSeeAnnotation = CanPlayerSee(client, i);
				if(!canClientSeeAnnotation && g_AnnotationCanBeSeenByClient[i][client])
				{
					// The player can no longer see the annotation
					HideAnnotationFromPlayer(client, i);
					g_AnnotationCanBeSeenByClient[i][client] = false;
				}
				else if (canClientSeeAnnotation && !g_AnnotationCanBeSeenByClient[i][client])
				{
					ShowAnnotationToPlayer(client, i);
					g_AnnotationCanBeSeenByClient[i][client] = true;
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:Timer_ExpireAnnotation(Handle:timer, any:annotation_id)
{
	g_AnnotationEnabled[annotation_id] = false;
	
	for(new client = 1; client < MaxClients; client++)
	{
		if(g_AnnotationCanBeSeenByClient[annotation_id][client])
		{
			HideAnnotationFromPlayer(client, annotation_id);
			g_AnnotationCanBeSeenByClient[annotation_id][client] = false;
		}
	}    
	return Plugin_Handled;
} 