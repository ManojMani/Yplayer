//
//  ViewController.swift
//  yPlayer
//
//  Created by SmartNet-MacBookPro on 9/30/17.
//  Copyright © 2017 Manoj. All rights reserved.
//

import UIKit
import ionicons
import MediaPlayer
import AVKit
import XCDYouTubeKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, UISearchBarDelegate {

    @IBOutlet weak var tblVideos: UITableView!
    
    @IBOutlet weak var viewWait: UIView!
    
    @IBOutlet weak var tblSuggestions: UITableView!
    
    fileprivate var apiKey = "AIzaSyBVN_5GhZPyXLeWo4mwsz5Aq9kLLXId_Ac"
    
    fileprivate var videosArray = [[String: AnyObject]]()
    
    fileprivate var suggestionsArray = [String]()
    
    fileprivate var selectedVideoIndex: Int!
    
    fileprivate let searchController = UISearchController(searchResultsController: nil)
    
    fileprivate var searchBarIsShown = false
    fileprivate let searchBar = UISearchBar()
    
    fileprivate var nextPageToken = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "YouTube"
        
        tblVideos.tableFooterView = UIView()
        
//        Setting the search icon using IonIcons
        
        let searchIcon = IonIcons.image(withIcon: ion_ios_search, size: 25, color: UIColor.white)
        
        let searchButton = UIBarButtonItem.init(image: searchIcon, style: .plain, target: self, action: #selector(ViewController.searchAction))
        navigationItem.rightBarButtonItem = searchButton
        
        searchVideosWith("")
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.hidesBackButton = true
        let value = UIInterfaceOrientation.portraitUpsideDown.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
//    MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableView == tblSuggestions ? suggestionsArray.count : videosArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == tblSuggestions {
            let cell = tableView.dequeueReusableCell(withIdentifier: "idCellSuggestion")
            cell?.textLabel?.text = suggestionsArray[indexPath.row]
            return cell!
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "idCellVideo") as? VideoCell
            let videoDetails = videosArray[indexPath.row]
            cell?.lblVideoTitle.text = videoDetails["title"] as? String
            
            cell?.lblDesc.text = videoDetails["channelTitle"] as? String
            
            let thumbUrlStr = videoDetails["thumbnail"] as? String
            
            cell?.imgViewThumbnail.loadImageUsingCache(withUrl: thumbUrlStr!)
            
            return cell!
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
//        Implementing the pagination
        if tableView == tblVideos {
            let lastElement = videosArray.count - 1
            if indexPath.row == lastElement {
                // handle your logic here to get more items, add it to dataSource and reload tableview
                searchVideosWith(searchBar.text!)
            }
        }
    }
    
//    MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView == tblSuggestions ? 45 : UIScreen.main.bounds.size.height*0.35
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if tableView == tblSuggestions {
            searchVideosWith(suggestionsArray[indexPath.row])
            tblSuggestions.isHidden = true
            searchBar.resignFirstResponder()
            nextPageToken = ""
            videosArray.removeAll()
        }else{
//            TODO: choose as per the limitations
            
//            Using XCDYouTubeKit for voilating all the restrictions
            
//            let videoDetails = videosArray[indexPath.row]
//            
//            let videoID = videoDetails["videoID"] as? String
//            
//            playVideo(videoID!)
            
//            Using youtube helper(follows all the limitations by youtube)
            selectedVideoIndex = indexPath.row
            performSegue(withIdentifier: "idSeguePlayer", sender: self)
        }
    }
    
    // MARK: Custom method implementation
    
    func searchVideosWith(_ urlStr: String) -> Void {
        self.viewWait.isHidden = false

        var urlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&q=\(urlStr)&type=video&key=\(apiKey)"
        
        if !nextPageToken.isEmpty {
            urlString = "https://www.googleapis.com/youtube/v3/search?pageToken=\(nextPageToken)&part=snippet&q=\(urlStr)&type=video&key=\(apiKey)"
        }
        
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        // Create a URL object based on the above string.
        let targetURL = URL(string: urlString)
        
        performGetRequest(targetURL) { (data, statusCode, error) in
            if statusCode == 200 && error == nil {
                // Convert the JSON data to a dictionary object.
                do {
                    let resultsDict = try JSONSerialization.jsonObject(with: data!, options: []) as! [String: AnyObject]
                    
                    self.nextPageToken = (resultsDict["nextPageToken"] as? String)!
                    // Get all search result items ("items" array).
                    let items = resultsDict["items"] as! [[String: AnyObject]]
                    
                    // Loop through all search results and keep just the necessary data.
                    
                    for item in items {
                        let snippetDict = item["snippet"] as? [String: AnyObject]
                        
                        // Gather the proper data depending on whether we're searching for channels or for videos.
                        var videoDetailsDict = [String: AnyObject]()
                        videoDetailsDict["title"] = snippetDict?["title"]
                        videoDetailsDict["channelTitle"] = snippetDict?["channelTitle"]
                        
                        let channelId = snippetDict?["channelId"] as? String
                        videoDetailsDict["channelId"] = channelId as AnyObject
                        
                        //                        let channelThumbnail = "https://www.googleapis.com/youtube/v3/channels?part=snippet&fields=items%2Fsnippet%2Fthumbnails%2Fdefault&id=\(channelId ?? "")&key=\(self.apiKey)"
                        
                        let thumbnails = snippetDict?["thumbnails"] as? [String: AnyObject]
                        
                        if let highImage = thumbnails?["high"] as? [String: AnyObject] {
                            videoDetailsDict["thumbnail"] = highImage["url"] as AnyObject
                        }else if let mediumImage = thumbnails?["medium"] as? [String: AnyObject] {
                            videoDetailsDict["thumbnail"] = mediumImage["url"] as AnyObject
                        }else if let defaultImage = thumbnails?["default"] as? [String: AnyObject] {
                            videoDetailsDict["thumbnail"] = defaultImage["url"] as AnyObject
                        }
                        let itemId = item["id"] as? [String: AnyObject]
                        videoDetailsDict["videoID"] = itemId?["videoId"]
                        
                        // Append the desiredPlaylistItemDataDict dictionary to the videos array.
                        self.videosArray.append(videoDetailsDict)
                        
                        // Reload the tableview.
                        self.tblVideos.reloadData()
                    }
                } catch {
                    print(error)
                }
            }
            else {
                print("HTTP Status Code = \(statusCode)")
                print("Error while loading channel videos: \(String(describing: error))")
            }
            
            // Hide the activity indicator.
            self.viewWait.isHidden = true
        }
    }
    
    func searchAction() -> Void {
        searchBarIsShown = !searchBarIsShown
        searchBar.placeholder = "Search YouTube"
        searchBar.delegate = self
        navigationItem.titleView = searchBarIsShown ? searchBar : UIView()
        searchBar.sizeToFit()
        if searchBarIsShown {
            searchBar.becomeFirstResponder()
        }else{
            searchBar.resignFirstResponder()
            tblSuggestions.isHidden = true
        }
    }
    
    func getSuggestions(_ queryStr: String) -> Void {
        
        var urlString = "http://suggestqueries.google.com/complete/search?client=youtube&ds=yt&client=firefox&q=\(queryStr)"
        
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        // Create a NSURL object based on the above string.
        let targetURL = URL(string: urlString)
        
        performGetRequest(targetURL) { (data, statusCode, error) in
            if statusCode == 200 && error == nil {
                // Convert the JSON data to a dictionary object.
                var str = String.init(data: data!, encoding: String.Encoding.utf8)
                    
                    
                    let escChar = "\""
                    

                    var stringsArray = [String]()

                    if (str?.contains(escChar))! {
                    str = str?.replacingOccurrences(of: escChar, with: "")
                        let strings = str?.components(separatedBy: ",")
                        
                        
                        for suggestion in strings! {
                            stringsArray.append(suggestion.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: ""))
                        }
                        self.suggestionsArray = stringsArray
                        self.tblSuggestions.isHidden = false
                        self.tblSuggestions.reloadData()
                }
            }
            else {
                print("HTTP Status Code = \(statusCode)")
                print("Error while loading channel videos: \(String(describing: error))")
            }
        }
    }
    
    func playVideo(_ videoID: String) -> Void {
        let value = UIInterfaceOrientation.landscapeLeft.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        let videoPlayerViewController = XCDYouTubeVideoPlayerViewController.init(videoIdentifier: videoID)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.moviePlayerPlaybackDidFinish(_:)), name: NSNotification.Name.MPMoviePlayerPlaybackDidFinish, object: videoPlayerViewController)
        present(videoPlayerViewController, animated: true, completion: nil)
    }
    
    func moviePlayerPlaybackDidFinish(_ notification: Notification) -> Void {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.MPMoviePlayerPlaybackDidFinish, object: notification.object)
        let finishReason = notification.userInfo?[MPMoviePlayerPlaybackDidFinishReasonUserInfoKey]
        print(finishReason!)
//        if (finishReason == MPMovieFinishReasonPlaybackError)
//        {
//            NSError *error = notification.userInfo[XCDMoviePlayerPlaybackDidFinishErrorUserInfoKey];
//            // Handle error
//        }
    }
    
    func performGetRequest(_ targetURL: URL!, completion: @escaping (_ data: Data?, _ HTTPStatusCode: Int, _ error: NSError?) -> Void) {
        
        let request = NSMutableURLRequest.init(url: targetURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 120)
        
        request.httpMethod = "GET"
        
        let session = URLSession.shared
        
        let dataTask = session.dataTask(with: request as URLRequest) {data,response,error in
            let httpResponse = response as? HTTPURLResponse
            
            if (error != nil) {
                print(error!)
            } else {
                print(httpResponse!)
            }
            
            DispatchQueue.main.async {
                //Update your UI here
                completion(data, (httpResponse?.statusCode)!, error as NSError?)
            }
        }
        dataTask.resume()
    }
    
    
    // MARK: - UISearchBar Delegate
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        getSuggestions(searchBar.text!)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
//        searchVideosWith(searchBar.text!)
        getSuggestions(searchBar.text!)
    }
    
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
    }
    
//    MARK: - Navigation
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "idSeguePlayer" {
            let playerViewController = segue.destination as! PlayerViewController
            playerViewController.videoID = videosArray[selectedVideoIndex]["videoID"] as? String
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

