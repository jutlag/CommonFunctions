//Request oAuth Token
// Solution to make REST API call from ServiceNOW to log analytics workspace using application credentials

var oAuthClient = new GlideOAuthClient();
var params ={grant_type:"client_credentials", resource:"https://api.loganalytics.io", client_id:"2673fc27-aa16-4825-951f-51a82b4f5641", client_secret:"SYuT_o88e6V2.vDpf6.-6-BlfhmFc16~N6"};
var json = new JSON();
var text = json.encode(params);
var tokenResponse = oAuthClient.requestToken('Azure TEST', text);
var token = tokenResponse.getToken();

// define variables and set them in the rest call
var header = {Authorization: "Bearer " + token.getAccessToken()}
var requestBody = {"query":"AzureActivity | where TimeGenerated > ago(1d)"}
var body_json = json.encode(requestBody);  // not sure if this is needed? might not need to encode request body  
var uri = "https://api.loganalytics.io/v1/workspaces/SYuT_o88e6V2.vDpf6.-6-BlfhmFc16~N6/query"

var r = new sn_ws.RESTMessageV2(); //Make rest call
r.setEndpoint(uri); //endpoint defined from var uri
r.setHttpMethod('POST'); // post method

r.setRequestHeader("Authorization", "Bearer " + token.getAccessToken()); //set auth header
//r.setRequestHeader("ContentType", "application/json"); // set content type
r.setRequestHeader('Content-Type','application/json');
r.setRequestBody(body_json); //set request body

var response = r.execute(); //execute rest call

var responseBody = response.getBody(); //capture the response
var httpResponseStatus = response.getStatusCode(); // capture the status code 
var httpResponseContentType = response.getHeader('Content-Type');
var parser = new JSONParser();
var parsed = {};
var httpResponseBody;

 
gs.log("http response status_code: " + httpResponseStatus); 
// Create an empty object that would contain the processed data
var finaldata = [];
//  if request is successful then parse the response body

if (httpResponseStatus == 200 && httpResponseContentType == 'application/json; charset=utf-8') {

    // Getting the data from the REST Call
    httpResponseBody = response.getBody();
    
    // Parse the Data into a Object that can be processed
    const obj = JSON.parse(httpResponseBody)
  
    // Create empty column array for use later
    var u_cols=[];


    
    // Loop through the columns and add them to the column array, we need this to build the final object structure
    for (var i = 0; i < obj.tables[0].columns.length; i++) {
       u_cols.push(obj.tables[0].columns[i].name);
    }

    //Show Type of column table for testing
    //gs.log(typeof u_cols);

    //Display the Columns array to validate the structure and integrity
    //gs.log(u_cols);

    // Now we process the Rest Data Row elements
    for (var j = 0; j < obj.tables[0].rows.length; j++) {
       //Create a Temporary structure so that we can add a column and row value to it
       var temp = new Object()
       for (var k = 0; k < obj.tables[0].rows[j].length; k++) {
          // Build the object table with column values from each column array element and add to it the value from the row structure
          temp[u_cols[k]] = obj.tables[0].rows[j][k]
       }
       //gs.log(JSON.stringify(temp))
      //Push each object into the array object
      finaldata.push(temp)
    }
  
   //Your final data is in the final data object and convert it to string to show. this is for demo only, you should be able to use the finaldata table as is
   gs.log(JSON.stringify(finaldata))
}  

//Inspect the finaldata object, it would be empty if the call failed for there was no data found
