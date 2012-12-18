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
	
	public static final String KEY_NAME = "settingsList";
	public static final String KEY_KIND = "Settings";
	public static final String ENTITY_KIND = "setting";
	public static final String ADMIN_NAME = "adminName";
	public static final String ADMIN_NUM = "adminNumName";
	public static final String CUR_EVENT = "eventID";
	public static final String SITE_NAME = "siteName";
	
	public Settings() {
		settingsKey = KeyFactory.createKey(KEY_KIND, KEY_NAME);
	}
	
	public Settings(String a, String n, int e, String s) {
		settingsKey = KeyFactory.createKey(KEY_KIND, KEY_NAME);
		setAdmin(a);
		setAdminNum(n);
		setCurEventID(e);
		setSiteName(s);
	}
	
	public Settings(Entity e) {
		setAdmin((String) e.getProperty(ADMIN_NAME));
		setAdminNum((String) e.getProperty(ADMIN_NUM));
		setCurEventID(((Long) e.getProperty(CUR_EVENT)).intValue());
		setSiteName((String) e.getProperty(SITE_NAME));
		settingsKey = KeyFactory.createKey(KEY_KIND, KEY_NAME);
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
		Entity setting = new Entity(ENTITY_KIND, settingsKey);
		setting.setProperty(ADMIN_NAME, admin);
		setting.setProperty(ADMIN_NUM, adminNum);
		setting.setProperty(CUR_EVENT, curEventID);
		setting.setProperty(SITE_NAME, siteName);
		
		return setting;
	}

	public void setSiteName(String siteName) {
		this.siteName = siteName;
	}

	public String getSiteName() {
		return siteName;
	}
	
}
