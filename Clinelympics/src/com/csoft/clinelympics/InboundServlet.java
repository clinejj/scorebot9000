package com.csoft.clinelympics;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.Date;

import javax.servlet.http.*;
import com.google.appengine.api.datastore.DatastoreService;
import com.google.appengine.api.datastore.DatastoreServiceFactory;
import com.google.appengine.api.datastore.Entity;
import com.google.appengine.api.datastore.Key;
import com.google.appengine.api.datastore.KeyFactory;
import javax.xml.parsers.*;
import javax.xml.transform.*;
import javax.xml.transform.dom.*;
import javax.xml.transform.stream.*;
import org.w3c.dom.*;

@SuppressWarnings("serial")
public class InboundServlet extends HttpServlet {
	
	private static final String cmdReg = "REGISTER";
	private static final String cmdScore = "SCORE";
    
	public void doPost(HttpServletRequest req, HttpServletResponse resp)
	throws IOException {
		boolean isValid = true;
		String smsresp = "";
		
		String smsid = req.getParameter("SmsSid");
		String accountid = req.getParameter("AccountSid");
		String number = req.getParameter("From");
		String body = req.getParameter("Body");
		
		DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
		
		Key textKey = KeyFactory.createKey("Texts", "textList");
		Entity text = new Entity("text", textKey);
		text.setProperty("SmsSid", smsid);
		text.setProperty("AccountSid", accountid);
		text.setProperty("From", number);
		text.setProperty("Body", body);
		text.setProperty("date", new Date());
		
		datastore.put(text);
		
		String[] split = body.split(" ");
		if (split[0].equalsIgnoreCase(cmdReg)) {
			if (split.length >= 2) {
				Player player = new Player(number, "name", body.substring(body.indexOf(" ")));
				datastore.put(player.createEntity());
			} else {
				isValid = false;
			}
		} else if (split[0].equalsIgnoreCase(cmdScore)) {
			if (split.length == 3) {
				Score score = new Score(number, Integer.parseInt(split[1]), Integer.parseInt(split[2]));
				datastore.put(score.createEntity());
			} else {
				isValid = false;
			}
		} else {
			isValid = false;
		}
		
		resp.setContentType("text/xml");
		resp.setCharacterEncoding("UTF-8");
		PrintWriter sos = resp.getWriter();
		
		if (isValid) {
			// return sms saying did not understand
			smsresp = "valid command!";
		} else {
			smsresp = "invalid command!";
		}
		
		Document dom;
		
		// instance of a DocumentBuilderFactory
	    DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
	    try {
	        // use factory to get an instance of document builder
	        DocumentBuilder db = dbf.newDocumentBuilder();
	        // create instance of DOM
	        dom = db.newDocument();

	        // create the root element
	        Element rootEle = dom.createElement("Response");

	        // create data elements and place them under root
	        Element e = dom.createElement("Sms");
	        e.appendChild(dom.createTextNode(smsresp));
	        rootEle.appendChild(e);

	        dom.appendChild(rootEle);

	        try {
	            Transformer tr = TransformerFactory.newInstance().newTransformer();
	            tr.setOutputProperty(OutputKeys.INDENT, "yes");
	            tr.setOutputProperty(OutputKeys.METHOD, "xml");
	            tr.setOutputProperty(OutputKeys.ENCODING, "UTF-8");

	            // send DOM to file
	            tr.transform(new DOMSource(dom), 
	                                 new StreamResult(sos));

	        } catch (TransformerException te) {
	            System.out.println(te.getMessage());
	        }
	    } catch (ParserConfigurationException pce) {
	        System.out.println(pce.getMessage());
	    }
		
		/*
		Key gameKey = KeyFactory.createKey("Games", "gameList");
		Entity game = new Entity("game", gameKey);
		game.setProperty("gameID", gameID);
		game.setProperty("gameName", gameName);
		game.setProperty("scoreType", scoreType);
		
		DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
		datastore.put(game);
		*/
		
		//resp.sendRedirect("/games.jsp");
	}
}
