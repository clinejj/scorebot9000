package com.csoft.scorebot;

import java.util.Random;

import com.google.appengine.api.datastore.Entity;
import com.google.appengine.api.datastore.Key;
import com.google.appengine.api.datastore.KeyFactory;

public class Name {
	private String name;
	private int rnd;
	private boolean isUsed;
	private Key nameKey;
	
	public static final String KEY_NAME = "nameList";
	public static final String KEY_KIND = "Names";
	public static final String ENTITY_KIND = "name";
	public static final String NAME = "Name";
	public static final String RND = "rnd";
	public static final String USED = "isUsed";
	
	public Name() {
		setNameKey(KeyFactory.createKey(KEY_KIND, KEY_NAME));
	}
	
	public Name(String n) {
		Random r = new Random(System.currentTimeMillis());
		setNameKey(KeyFactory.createKey(KEY_KIND, KEY_NAME));
		setName(n);
		setRnd(r.nextInt());
		setUsed(false);
	}
	
	public Name(Entity eName) {
		setNameKey(KeyFactory.createKey(KEY_KIND, KEY_NAME));
		setName((String) eName.getProperty(NAME));
		setRnd(((Long) eName.getProperty(RND)).intValue());
		setUsed((Boolean) eName.getProperty(USED));
	}

	public void setName(String name) {
		this.name = name;
	}

	public String getName() {
		return name;
	}

	public void setRnd(int rnd) {
		this.rnd = rnd;
	}

	public int getRnd() {
		return rnd;
	}

	public void setUsed(boolean isUsed) {
		this.isUsed = isUsed;
	}

	public boolean isUsed() {
		return isUsed;
	}

	public void setNameKey(Key nameKey) {
		this.nameKey = nameKey;
	}

	public Key getNameKey() {
		return nameKey;
	}

	public Entity createEntity() {
		Entity n = new Entity(ENTITY_KIND, nameKey);
		n.setProperty(NAME, name);
		n.setProperty(RND, rnd);
		n.setProperty(USED, isUsed);
		
		return n;
	}
}
