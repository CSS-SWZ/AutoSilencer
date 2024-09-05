#include <sourcemod>
#include <sdktools_functions>
#include <sdkhooks>
#include <clientprefs>

#pragma newdecls required

Handle hCookie;
bool Toggle[MAXPLAYERS + 1] = {true, ...};
bool IsSilenced[2048];

int RussianLanguageId;

public Plugin myinfo =
{
	name = "AutoSilencer",
	author = "hEl",
	description = "Auto silence for m4a1",
	version = "1.0",
	url = ""
};

public void OnPluginStart() 
{
	if((RussianLanguageId = GetLanguageByCode("ru")) == -1)
	{
		SetFailState("Cant find russian language (see languages.cfg)");
	}
	HookEvent("item_pickup", OnItemPickUp);

	SetCookieMenuItem(CookieMenuH, 0, "Auto Silencer");
	hCookie = RegClientCookie("AutoSilencer", "", CookieAccess_Private);

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && AreClientCookiesCached(i))
		{
			OnClientCookiesCached(i);
		}
	}
}

public void OnItemPickUp(Event hEvent, const char[] szName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));

	if(!Toggle[iClient])
		return;

	int iSlot;
	char szWeapon[4];
	hEvent.GetString("item", szWeapon, sizeof(szWeapon));

	switch(szWeapon[1])
	{
		// USP
		//case 's':	iSlot = 1;

		// M4A1
		case '4':	iSlot = 0;

		default:	return;
	}

	int iWeapon = GetPlayerWeaponSlot(iClient, iSlot);
	if (iWeapon != -1)
	{
		if(!IsSilenced[iWeapon])
		{
			SetEntProp(iWeapon, Prop_Send, "m_bSilencerOn", 1);
			SetEntProp(iWeapon, Prop_Send, "m_weaponMode", 1);
			IsSilenced[iWeapon] = true;
		}
	}
}

public void CookieMenuH(int iClient, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	switch(action)
	{
		case CookieMenuAction_DisplayOption:
		{
			FormatEx(buffer, maxlen, "%s: [%s]", GetClientLanguage(iClient) == RussianLanguageId ? "Авто-Глушитель":"Auto Silencer", Toggle[iClient] ? "✔":"×");
		}
		case CookieMenuAction_SelectOption:
		{
			ToggleClientAutoSilencer(iClient);
			ShowCookieMenu(iClient);
		}
	}
}

void ToggleClientAutoSilencer(int iClient)
{
	Toggle[iClient] = !Toggle[iClient];
	SaveClientCookies(iClient);
	PrintHintText(iClient, "%s: [%s]", GetClientLanguage(iClient) == RussianLanguageId ? "Авто-Глушитель":"Auto Silencer", Toggle[iClient] ? "✔":"×");
}

void SaveClientCookies(int iClient)
{
	if(AreClientCookiesCached(iClient))
	{
		SetClientCookie(iClient, hCookie, Toggle[iClient] ? "1":"0");
	}
}

public void OnClientCookiesCached(int iClient)
{
	if(IsFakeClient(iClient))
		return;

	char szBuffer[8];
	GetClientCookie(iClient, hCookie, szBuffer, 8);
	
	if(szBuffer[0])
	{
		Toggle[iClient] = view_as<bool>(StringToInt(szBuffer));
	}
}

public void OnClientDisconnect(int iClient)
{
	Toggle[iClient] = true;
}

public void OnEntityDestroyed(int iEntity)
{
	if(iEntity > MaxClients && iEntity < 2048)
	{
		IsSilenced[iEntity] = false;
	}
}

