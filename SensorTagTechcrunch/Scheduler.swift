import Foundation

class Scheduler: NSObject {
    var data: NSMutableData = NSMutableData()
    
    func connectToWebApi() {
        var urlPath = "https://outlook.office365.com/api/v1.0/me/calendarview?startDateTime=2014-10-01T01:00:00Z&endDateTime=2016-10-31T23:00:00Z"

        let username = "joeheenan@postureio.onmicrosoft.com"
        let password = "@377rector"
        
        // set up the base64-encoded credentials
        
        let PasswordString = "\(username):\(password)"
        let PasswordData = PasswordString.dataUsingEncoding(NSUTF8StringEncoding)
        let base64EncodedCredential = PasswordData!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength)
        
        var url: NSURL = NSURL(string: urlPath)!

        
        var request: NSMutableURLRequest = NSMutableURLRequest(URL: url)
        request.setValue("Basic \(base64EncodedCredential)", forHTTPHeaderField: "Authorization")
        request.HTTPMethod = "GET"
        
        let queue:NSOperationQueue = NSOperationQueue()
        let urlConnection = NSURLConnection(request: request, delegate: self)
        urlConnection!.start()
    }
    
    
    //NSURLConnection delegate method
    func connection(connection: NSURLConnection!, didFailWithError error: NSError!) {
        println("Failed with error:\(error.localizedDescription)")
    }
    
    //NSURLConnection delegate method
    func connection(didReceiveResponse: NSURLConnection!, didReceiveResponse response: NSURLResponse!) {
        //New request so we need to clear the data object
        self.data = NSMutableData()
    }
    
    //NSURLConnection delegate method
    func connection(connection: NSURLConnection!, didReceiveData data: NSData!) {
        //Append incoming data
        
        let json = JSON(data: data)
        if let appName = json["value"][0]["Subject"].string {
            println("SwiftyJSON: \(appName)")
        }
        

    }
    
    //NSURLConnection delegate method
    func connectionDidFinishLoading(connection: NSURLConnection!) {
        NSLog("connectionDidFinishLoading");
}
}