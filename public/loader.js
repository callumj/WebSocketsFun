function bootup()
{
	var previousX = null;
	var previousY = null;


	var socket = new WebSocket("ws://localhost:8090");
	socket.onopen = function(){  
		pin = prompt("Pin please");
		socket.send("PIN:" + pin);
	}

	socket.onmessage = function(msg) {
		payload = jQuery.parseJSON(msg.data);
		if (payload != null && payload.event != null)
		{
			payload.x = Math.round(payload.x * 1000) / 1000;
			payload.y = Math.round(payload.y * 1000) / 1000;
		
			if (previousX != null) {
				//props to http://www.p01.org/releases/Drawing_lines_in_JavaScript/
				var lineLength = Math.sqrt( (previousX-payload.x)*(previousX-payload.x)+(previousY-payload.y)*(previousY-payload.y));
				for( var i=0; i<lineLength; i++ )
				{
					x_val = Math.round(previousX+(payload.x-previousX)*i/lineLength);
					y_val = Math.round(previousY+(payload.y-previousY)*i/lineLength);
								
					dot = $("<div class=\"dot\" style=\"position: absolute; top: " + y_val + "%; left: " + x_val + "%; width: 2%; height: 2%; background-color: black\"></div>");
					$("body").append(dot);
				}
			}
		
			dot = $("<div class=\"dot\" style=\"position: absolute; top: " + payload.y + "%; left: " + payload.x + "%; width: 2%; height: 2%; background-color: black\"></div>");
			$("body").append(dot);
		
			previousX = payload.x;
			previousY = payload.y;
		}
	}
}
/*

jquery_inject=document.createElement('scr'+'ipt');
jquery_inject.setAttribute("type", "text/javscript");
jquery_inject.setAttribute("src", "http://ajax.googleapis.com/ajax/libs/jquery/1.6.2/jquery.min.js");
jquery_inject.setAttribute("charset", "utf-8");
document.body.appendChild(jquery_inject);*/

var head= document.getElementsByTagName('head')[0];
var script= document.createElement('script');
script.type= 'text/javascript';
script.src= 'http://ajax.googleapis.com/ajax/libs/jquery/1.6.2/jquery.min.js';
head.appendChild(script);

bootup();