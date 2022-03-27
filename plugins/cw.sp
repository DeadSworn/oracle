#include <sourcemod>
#include <sdkhooks>
// mode cvar and other:
// anti kick afk player
// hud message scope and winner
// disable all rtd effects
char red_team[32] = "RED TEAM (CLEAR)";
char blue_team[32] = "BLUE TEAM (CLEAR)";
int point_red = 0;
int point_blue = 0;
int password_server = 0;
bool cw_status = false;
int round_limit = 0;
int rount_count = 0;
public void OnPluginStart()
{
	RegAdminCmd("sm_red", Command_red_team, ADMFLAG_CONVARS, "");
	RegAdminCmd("sm_blue", Command_blue_team, ADMFLAG_CONVARS, "");
	RegAdminCmd("sm_round_limit", Command_round_limit, ADMFLAG_CONVARS, "");
	RegAdminCmd("sm_round_reset", Command_round_reset, ADMFLAG_CONVARS, "");
	RegAdminCmd("sm_point_red", Command_point_red, ADMFLAG_CONVARS, "");
	RegAdminCmd("sm_point_blue", Command_point_blue, ADMFLAG_CONVARS, "");
	RegAdminCmd("sm_password_get", Command_password_get, ADMFLAG_CONVARS, "");
	RegAdminCmd("sm_cw_enable", Command_cw_enable, ADMFLAG_CONVARS, "");
	RegAdminCmd("sm_cw_disable", Command_cw_disable, ADMFLAG_CONVARS, "");
	HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_Post);
}
public Action OnRoundEnd(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	if (cw_status)
	{
		rount_count++;
		int team = GetEventInt(hEvent, "team");
		if (team == 2)
		{
			point_red++;
		}
		if (team == 3)
		{
			point_blue++;
		}
		SetHudTextParams(-1.0, 0.2, 10.0, 255, 255, 255, 255);
		PrintCenterTextAll("");
		if (round_limit == rount_count)
		{
			if (point_red > point_blue)
			{
				for (new i = 1;  i <= MaxClients;  i++)
				{
					if (IsValidClient(i))
					{
						SetGlobalTransTarget(i);
						ShowHudText(i, -1, "%s WINNER", red_team);
					}
				}
			}
			else
			{
				for (new i = 1;  i <= MaxClients;  i++)
				{
					if (IsValidClient(i))
					{
						SetGlobalTransTarget(i);
						ShowHudText(i, -1, "%s WINNER", blue_team);
					}
				}
			}
		}
		else
		{
			for (new i = 1;  i <= MaxClients;  i++)
			{
				if (IsValidClient(i))
				{
					SetGlobalTransTarget(i);
					ShowHudText(i, -1, "%s : %i\n %s : %i", red_team, point_red, blue_team, point_blue);
				}
			}
		}
	}
}
public Action:Command_round_limit(client, args)
{
	char arg1[16] = "";
	GetCmdArg(1, arg1, sizeof(arg1));
	int parameter_value = StringToInt(arg1);
	round_limit = parameter_value;
	return Plugin_Handled;
}
public Action:Command_round_reset(client, args)
{
	point_red = 0;
	point_blue = 0;
	round_limit = 15;
	rount_count = 0;
	return Plugin_Handled;
}
public Action:Command_point_red(client, args)
{
	char arg1[16] = "";
	GetCmdArg(1, arg1, sizeof(arg1));
	int parameter_value = StringToInt(arg1);
	point_red = parameter_value;
	return Plugin_Handled;
}
public Action:Command_point_blue(client, args)
{
	char arg1[16] = "";
	GetCmdArg(1, arg1, sizeof(arg1));
	int parameter_value = StringToInt(arg1);
	point_blue = parameter_value;
	return Plugin_Handled;
}
public Action:Command_cw_enable(client, args)
{
	cw_status = true;
	password_server = GeneratePasword();
	ServerCommand("sv_password %i", password_server);
	ServerCommand("mp_idledealmethod 0");
	ServerCommand("mp_idlemaxtime 60");
	ServerCommand("mp_timelimit 360");
	ServerCommand("sm plugins unload rtd");
	point_red = 0;
	point_blue = 0;
	red_team = "RED TEAM (CLEAR)";
	blue_team = "BLUE TEAM (CLEAR)";
	round_limit = 15;
	rount_count = 0;
	return Plugin_Handled;
}
public Action:Command_cw_disable(client, args)
{
	cw_status = false;
	ServerCommand("exec tf2server.cfg")
	ServerCommand("mp_idledealmethod 1");
	ServerCommand("mp_idlemaxtime 3");
	ServerCommand("mp_timelimit 60");
	ServerCommand("sm plugins load rtd");
	point_red = 0;
	point_blue = 0;
	red_team = "RED TEAM (CLEAR)";
	blue_team = "BLUE TEAM (CLEAR)";
	round_limit = 15;
	rount_count = 0;
	return Plugin_Handled;
}
public Action:Command_red_team(client, args)
{
	char arg1[32] = "";
	GetCmdArg(1, arg1, sizeof(arg1));
	red_team = arg1;
	return Plugin_Handled;
}
public Action:Command_blue_team(client, args)
{
	char arg1[32] = "";
	GetCmdArg(1, arg1, sizeof(arg1));
	blue_team = arg1;
	return Plugin_Handled;
}
public Action:Command_password_get(client, args)
{
	PrintToChat(client, "password: %i", password_server);
	return Plugin_Handled;
}

public int GeneratePasword()
{
	int password = 0;
	char temp_password[8];
	for (new i = 0; i < 8; i++)
	{
		int temp = GetRandomInt(0, 9);
		char buffer[4];
		IntToString(temp, buffer, sizeof(buffer));
		temp_password[i] = buffer[0];
	}
	password = StringToInt(temp_password);
	return password;
}
stock bool:IsValidClient(iClient)
{
	if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return false;
	return true;
}