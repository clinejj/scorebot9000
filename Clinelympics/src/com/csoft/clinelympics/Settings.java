package com.csoft.clinelympics;

import com.google.appengine.api.datastore.Entity;
import com.google.appengine.api.datastore.Key;
import com.google.appengine.api.datastore.KeyFactory;

public class Settings {
	private String admin;
	private String adminNum;
	private int curEventID;
	private String siteName;
	private Key settingsKey;
	
	public static final String keyName = "settingsList";
	public static final String keyKind = "Settings";
	public static final String entityKind = "setting";
	public static final String adminName = "adminName";
	public static final String adminNumName = "adminNumName";
	public static final String curEventName = "eventID";
	public static final String siteNameName = "siteName";
	
	public Settings() {
		settingsKey = KeyFactory.createKey(keyKind, keyName);
	}
	
	public Settings(String a, String n, int e, String s) {
		settingsKey = KeyFactory.createKey(keyKind, keyName);
		setAdmin(a);
		setAdminNum(n);
		setCurEventID(e);
		setSiteName(s);
	}
	
	public Settings(Entity e) {
		setAdmin((String) e.getProperty(adminName));
		setAdminNum((String) e.getProperty(adminNumName));
		setCurEventID(((Long) e.getProperty(curEventName)).intValue());
		setSiteName((String) e.getProperty(siteNameName));
		settingsKey = KeyFactory.createKey(keyKind, keyName);
	}
	
	public void setAdmin(String admin) {
		this.admin = admin;
	}
	public String getAdmin() {
		return admin;
	}
	public void setAdminNum(String adminNum) {
		this.adminNum = adminNum;
	}
	public String getAdminNum() {
		return adminNum;
	}
	public void setCurEventID(int curEventID) {
		this.curEventID = curEventID;
	}
	public int getCurEventID() {
		return curEventID;
	}
	public Key getSettingsKey() {
		return settingsKey;
	}
	
	public Entity createEntity() {
		Entity setting = new Entity(entityKind, settingsKey);
		setting.setProperty(adminName, admin);
		setting.setProperty(adminNumName, adminNum);
		setting.setProperty(curEventName, curEventID);
		setting.setProperty(siteNameName, siteName);
		
		return setting;
	}

	public void setSiteName(String siteName) {
		this.siteName = siteName;
	}

	public String getSiteName() {
		return siteName;
	}
	
}
