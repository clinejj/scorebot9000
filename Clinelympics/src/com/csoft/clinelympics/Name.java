package com.csoft.clinelympics;

import java.util.Random;

import com.google.appengine.api.datastore.Entity;
import com.google.appengine.api.datastore.Key;
import com.google.appengine.api.datastore.KeyFactory;

public class Name {
	private String name;
	private int rnd;
	private boolean isUsed;
	private Key nameKey;
	
	public static final String keyName = "nameList";
	public static final String keyKind = "Names";
	public static final String entityKind = "name";
	public static final String nameStr = "Name";
	public static final String rndStr = "rnd";
	public static final String usedStr = "isUsed";
	
	public Name() {
		setNameKey(KeyFactory.createKey(keyKind, keyName));
	}
	
	public Name(String n) {
		Random r = new Random(System.currentTimeMillis());
		setNameKey(KeyFactory.createKey(keyKind, keyName));
		setName(n);
		setRnd(r.nextInt());
		setUsed(false);
	}
	
	public Name(Entity eName) {
		setNameKey(KeyFactory.createKey(keyKind, keyName));
		setName((String) eName.getProperty(nameStr));
		setRnd(((Long) eName.getProperty(rndStr)).intValue());
		setUsed((Boolean) eName.getProperty(usedStr));
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
		Entity n = new Entity(entityKind, nameKey);
		n.setProperty(nameStr, name);
		n.setProperty(rndStr, rnd);
		n.setProperty(usedStr, isUsed);
		
		return n;
	}
}
