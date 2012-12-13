package com.csoft.clinelympics;

import com.google.appengine.api.datastore.Entity;
import com.google.appengine.api.datastore.Key;
import com.google.appengine.api.datastore.KeyFactory;
import com.google.appengine.api.users.User;

public class Settings {
	private User admin;
	private String adminNum;
	private int curEventID;
	private Key settingsKey;
	
	public static final String keyName = "settingsList";
	public static final String keyKind = "Settings";
	public static final String entityKind = "setting";
	public static final String adminName = "adminName";
	public static final String adminNumName = "adminNumName";
	public static final String curEventName = "eventsIDName";
	
	public Settings() {
		settingsKey = KeyFactory.createKey(keyKind, keyName);
	}
	
	public Settings(User a, String n, int e) {
		settingsKey = KeyFactory.createKey(keyKind, keyName);
		setAdmin(a);
		setAdminNum(n);
		setCurEventID(e);
	}
	
	public Settings(Entity e) {
		setAdmin((User) e.getProperty(adminName));
		setAdminNum((String) e.getProperty(adminNumName));
		setCurEventID(((Long) e.getProperty(curEventName)).intValue());
		settingsKey = KeyFactory.createKey(keyKind, keyName);
	}
	
	public void setAdmin(User admin) {
		this.admin = admin;
	}
	public User getAdmin() {
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
		
		return setting;
	}
	
}
