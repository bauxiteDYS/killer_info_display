#include <sourcemod>
#include <clientprefs>
#include <neotokyo>

#pragma semicolon 1
#pragma newdecls required


#define DEBUG false

ConVar cvarEnabled;
ConVar cvarTextRelay;
ConVar cvarDuration;
bool g_enabled;
bool g_text;
bool g_lateLoad;
int g_duration;
Cookie KillerCookie;
static bool g_wantsText[NEO_MAXPLAYERS+1];
static char className[][] = {
	"Unknown",
	"Recon",
	"Assault",
	"Support"
};

public Plugin myinfo = {
	name = "NT Killer Info",
	author = "bauxite, credits to Berni, gH0sTy, Smurfy1982, Snake60",
	description = "Displays the name, weapon, health and class of player that killed you, optionally relays info to chat",
	version = "0.3.0",
	url = "https://github.com/bauxiteDYS/SM-NT-Killer-Info",
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_lateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	KillerCookie = RegClientCookie("killer_info_text", "killer info text preference", CookieAccess_Public);
	SetCookieMenuItem(KillerTextMenu, KillerCookie, "killer info text");
}

public void OnAllPluginsLoaded()
{
	ConVar cvarKIDVersion = FindConVar("kid_version");
	
	if(cvarKIDVersion != null) // convars persist after unload, so re-loads might fail if they depend on convars existence
	{
		SetFailState("[NT Killer Info] Error: A different Killer Info plugin is loaded");
	}
	
	cvarEnabled = CreateConVar("kid_printtopanel", "1", "Enable Killer Info Panel display",_, true, 0.0, true, 1.0);
	cvarTextRelay = CreateConVar("kid_text_relay", "1", "Enable Text Relay",_, true, 0.0, true, 1.0);
	cvarDuration = CreateConVar("kid_panel_duration", "9", "Panel duration in seconds",_, true, 1.0, true, 15.0);
	HookConVarChange(cvarEnabled, CVARS_Changed);
	HookConVarChange(cvarTextRelay, CVARS_Changed);
	HookConVarChange(cvarDuration, CVARS_Changed);
	AutoExecConfig(true);
	
	if(g_lateLoad) // OnAllPluginsLoaded is called on late load
	{
		for(int client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client))
			{
				OnClientCookiesCached(client);
			}
		}
	}
}

public void OnConfigsExecuted()
{
	UpdateCvars();
}

void CVARS_Changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	UpdateCvars();
}

void UpdateCvars()
{
	g_enabled = cvarEnabled.BoolValue;
	g_text = cvarTextRelay.BoolValue;
	g_duration = cvarDuration.IntValue;
}

public void KillerTextMenu(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	if (action == CookieMenuAction_SelectOption) 
	{
		KillerCustomMenu(client);
	}
}

public Action KillerCustomMenu(int client)
{
	Menu menu = new Menu(KillerCustomMenu_Handler, MENU_ACTIONS_DEFAULT);
	menu.AddItem("on", "Enable");
	menu.AddItem("off", "Disable");
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int KillerCustomMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End) 
	{
		delete menu;
	}
	else if (action == MenuAction_Select) 
	{
		int client = param1;
		int selection = param2;

		char option[10];
		menu.GetItem(selection, option, sizeof(option));

		if (StrEqual(option, "on")) 
		{ 
			SetClientCookie(client, KillerCookie, "1");
			g_wantsText[client] = true;
		} 
		else 
		{
			SetClientCookie(client, KillerCookie, "0");
			g_wantsText[client] = false;
		}
	}
	
	return 0;
}

public void OnClientCookiesCached(int client)
{
	int iWantsText;
	char bufWantsText[2];
	GetClientCookie(client, KillerCookie, bufWantsText, 2);
	iWantsText = StringToInt(bufWantsText);
	
	if(iWantsText == 1)
	{
		g_wantsText[client] = true;
	}
	else
	{
		g_wantsText[client] = false;
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{	
	if(!g_enabled)
	{
		return;
	}
	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	#if DEBUG
	if (client == 0 || attacker == 0)
	#else
	if (client == 0 || attacker == 0 || client == attacker)
	#endif
	{
		return;
	}

	int healthLeft = GetClientHealth(attacker);
	
	char weapon[32];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	float clientVec[3];
	float attackerVec[3];
	GetClientAbsOrigin(client, clientVec);
	GetClientAbsOrigin(attacker, attackerVec);
	float distance = GetVectorDistance(clientVec, attackerVec) * 0.0254;
	
	// Print To Panel, Handle style = GetMenuStyleHandle(MenuStyle_Radio);
	
	Panel panel = new Panel();
	
	char buffer[64];
	Format(buffer, sizeof(buffer), "%N killed you", attacker);
	panel.SetTitle(buffer, false);
	
	panel.DrawItem("", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE|ITEMDRAW_DISABLED);
	
	Format(buffer, sizeof(buffer), "%-10s%s", "Weapon:", weapon);
	panel.DrawItem(buffer, ITEMDRAW_DEFAULT);
	
	Format(buffer, sizeof(buffer), "%-13s%d HP", "Health:", healthLeft);
	panel.DrawItem(buffer, ITEMDRAW_DEFAULT);
	
	Format(buffer, sizeof(buffer), "%-14s%s", "Class:", className[GetPlayerClass(attacker)]);
	panel.DrawItem(buffer, ITEMDRAW_DEFAULT);
		
	Format(buffer, sizeof(buffer), "%-11s%.1f Meters", "Distance:", distance);
	panel.DrawItem(buffer, ITEMDRAW_DEFAULT);
		
	panel.DrawItem("", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE|ITEMDRAW_DISABLED);

	//SetPanelCurrentKey(panel, 2);
	
	panel.Send(client, Handler_DoNothing, g_duration);
	delete panel;

	if (g_text && g_wantsText[client] == true)
	{
		ClientCommand(client, "say_team %d %s %s", healthLeft, className[GetPlayerClass(attacker)], weapon);
	}
	
	return;
}

public int Handler_DoNothing(Menu menu, MenuAction action, int param1, int param2) 
{
	return 0;
}
