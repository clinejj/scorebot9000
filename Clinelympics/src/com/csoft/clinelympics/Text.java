package com.csoft.clinelympics;

import java.util.Date;

import com.google.appengine.api.datastore.Entity;
import com.google.appengine.api.datastore.Key;
import com.google.appengine.api.datastore.KeyFactory;

public class Text {
	private String smsID;
	private String accountSID;
	private String from;
	private String body;
	private Date sentDate;
	private Key textKey;
	
	public static final String keyName = "textList";
	public static final String keyKind = "Texts";
	public static final String entityKind = "text";
	public static final String smsIDName = "SmsSid";
	public static final String accountSIDName = "AccountSid";
	public static final String fromName = "From";
	public static final String bodyName = "Body";
	public static final String sentDateName = "date";

	public Text() {
		setTextKey(KeyFactory.createKey(keyKind, keyName));
	}
	
	public Text(String sID, String aID, String f, String b) {
		setTextKey(KeyFactory.createKey(keyKind, keyName));
		setSmsID(sID);
		setAccountSID(aID);
		setFrom(f);
		setBody(b);
		setSentDate(new Date());
	}
	
	public Text(Entity eText) {
		setTextKey(KeyFactory.createKey(keyKind, keyName));
		setSmsID((String) eText.getProperty(smsIDName));
		setAccountSID((String) eText.getProperty(accountSIDName));
		setFrom((String) eText.getProperty(fromName));
		setBody((String) eText.getProperty(bodyName));
		setSentDate((Date) eText.getProperty(sentDateName));
	}

	public void setSmsID(String smsID) {
		this.smsID = smsID;
	}

	public String getSmsID() {
		return smsID;
	}

	public void setAccountSID(String accountSID) {
		this.accountSID = accountSID;
	}

	public String getAccountSID() {
		return accountSID;
	}

	public void setFrom(String from) {
		this.from = from;
	}

	public String getFrom() {
		return from;
	}

	public void setBody(String body) {
		this.body = body;
	}

	public String getBody() {
		return body;
	}

	public void setSentDate(Date sentDate) {
		this.sentDate = sentDate;
	}

	public Date getSentDate() {
		return sentDate;
	}

	public void setTextKey(Key textKey) {
		this.textKey = textKey;
	}

	public Key getTextKey() {
		return textKey;
	}
	
	public Entity createEntity() {
		Entity text = new Entity(entityKind, textKey);
		text.setProperty(smsIDName, smsID);
		text.setProperty(accountSIDName, accountSID);
		text.setProperty(fromName, from);
		text.setProperty(bodyName, body);
		text.setProperty(sentDateName, sentDate);
		
		return text;
	}
}
