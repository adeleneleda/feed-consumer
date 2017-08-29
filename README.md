# Feed Consumer

An odds feed consumer written in Elixir

## Overview
======
A feed consumer written in Elixir that fetches odds from a given odds feed URL, validates them to ensure completeness and inclusion in the match schedule, and records them to an S3 bucket.

The following is the general algorithm in the pipe paradigm, 

    Odds Feed
    |> Consume odds
    |> Validate consumed odds
    |> Check if odds' match is in schedule
    |> Save in AWS S3


## Components:
======
### I. Primary
The following are the main components that work together to achieve the above pipeline:

A. **Consumers**

   ```FeedConsumer.Request``` uses HTTPoison as an HTTP client to make requests to the match odds and schedule URLs. Results were then parsed by Poison (for JSON values) and Msgpax (for message packs).
  
B. **Validators**

   To help ensure data consistency and completeness, ```FeedConsumer.Validator``` validates raw data before it enters the main pipeline to ensure processing only occurs for valid and complete data.
   
   Validations include checks for:
   * Valid **outcomes**: should have and only have odds for 1, 2, and x
   * Valid **kickoff times**: the kickoff time from the odd must only deviate from the match's schedule kickoff time by a certain threshold (i.e. 1 hour)

C. **DataStore**

   Storing the matches data would make it easy for the different processes to read and update it without the need for it to be passed around much. For this purpose, ```FeedConsumer.DataStore``` stores match data to the ETS (Erlang Term Storage), an in-memory datastore. Before storage, match data is also transformed to make querying and lookup later in the processing easier.

D. **Data Structs**

   Data structs provide a way to parse, format, verify, and standardize raw input. With data structs in place, it is also easier to convert raw data from different feeds to a standard format used in processing. Whenever, a change in format occurs or the need for multiple formats arise, raw data can be transformed as long as the end format is consistent to the expected (i.e. one used in processing). 
   
   FeedConsumer has 2 data structs: ```FeedConsumer.Struct.OddMatch``` and ```FeedConsumer.Struct.SchedMatch```. ```OddMatch``` standardizes the structure of odd data from the odds feed to have the keys :name, :kickoff, and :outcomes. ```SchedMatch```, on the other hand, takes care of parsing the matches from the Schedule API as well as formatting them for writing to AWS S3.

E. **S3**

   ```FeedConsumer.S3``` handles the writing and/or updating of JSON files to AWS S3 with ExAWS in hand.

### II. Utilities:

The following are the main utility components that help in tracking results and increasing match rate.
   

#### A. FileLogger

Tracking the close matches (and mismatches) that happened between the Odds Feed and the Schedule API would help us know if there's anything that needs to be adjusted on the system. For this purpose, logs are kept for the following scenarios. Note that these aims to provide more visibility but is optional and could be turned off when space and/or speed concerns arise.

a. **Close Matches**

   Guided by one of the discussion points on taking into account possible differences on team names between the two sources, match names (from the Odds Feed) not found in our schedule are logged together with the closest matching match name that we have. To ensure that only close matches are included, a threshold for the Jaro distance (i.e. 0.88) is set and only matches equal or greater than it are logged to the file. One result from this log is the discovery that ```Darlington 1883``` is used interchangably with ```Darlington FC```.
   
   
       Match Name #1: Darlington 1883 - Spennymoor Town
       Match Name #2: Darlington FC - Spennymoor Town
       Jaro Distance: 0.9380905832518737
   
   
* **Kickoff Mismatch**

  Tournaments from the Odds Feed and the Schedule API can only be matched by name as the IDs of the two sources are not synced. To help ensure that the match is indeed correct, checks are also made with the kickoff time which is also present in both sources. A certain threshold for the kickoff time deviation is set and whenever the difference is less than the set threshold, a match is found. From data, 1 hour (3,600 seconds) deviation seem acceptable as most of the kickoff times really don't match and has 1 hour discrepancy. This log would be helpful in checking if the threshold should be adjusted.
  
      
      Timestamp: [2017-08-28T13:22:56.247662Z]
      ID: 12349508
      Match Name: KAA Gent - Zulte Waregem
      Kickoff (from Sched): 1503936000
      Kickoff (from Odds):  1503939600
      Diff: 3600



* **Invalid Outcomes**
  
  For tracking and assessment purposes, outcomes that are incomplete are also logged to determine the frequency and/or necessary adjustments in the system's parsers.
  
      Timestamp: [2017-08-28T13:32:00.574007Z]
      Match Name: Konak Belediyesi - Gintra Universitetas
      Invalid Odd: %{"1" => "3.5", "x" => "3.25"}
  
* **Actions**

   A record on when calls to the Odds Feed and the Matches URL were made and the amount of data each call gave.



#### B. Substitution

   As we have mentioned in the *Close Matches* point of the *File Logger* subsection above, acceptable equivalents can be discovered by the log of close matches in match names. To be able to also take into account these equivalents, copies for the equivalents listed in ```FeedConsumer.Substitution``` are also saved in the database.
   
   For example, when saving a match played by ```Darlington 1883``` and ```Spennymoor Town```, the match is saved with ```Darlington 1883 - Spennymoor Town``` as the name and another copy is saved with the name ```Darlington FC - Spennymoor Town```. With this, whatever team name is used by the Odds Feed, a match will be found.



## GenServer Structure (OTP)
======
At the start of the application, match schedule data is fetched from the Schedule API and an odds fetch is scheduled to be sent after 1 minute (60,000 ms). The fetch to the Schedule API has also schedule another fetch after an hour (3,600,000 ms). In summary, the Schedule API is polled every hour and the Odds Feed every munute. Frequency can be adjusted by updating ```FeedConsumer.Server```.

## API Format:
======

#### Schedule

    [ 
      {
          "id":10678636,
          "team1_id":4890,
          "team2_id":6022,
          "team1_name":"Germany",
          "team2_name":"Czech Republic",
          "tournament_id":454,
          "kickoff_at":1497801600
        }
    ]

where:

* id: our ID
* team1_name: Home Team
* team2_name: Away Team
* tournament_id: Match ID



#### Odds Feed (Odds Provider)

    {
      "122474542" => %{
                      "kickOf" => 1503802800, 
                      "name" => "Tauro FC - Plaza Amador",
                      "outcomes" => [
                        ["114585828", "1", "2.4"], 
                        ["92239542", "2", "2.88"],
                        ["121837756", "x", "2.88"]
                      ]
                    }
     }
     

where:

* topmost key (122474542): odd ID internal to our odds provider
* outcomes: [[outcome-id-internal-to-odds-provider, {1, x, 2}, odd]]          
          



## Points for Discussion:
======

1. **How would you structure this project to support multiple feeds of different formats?**


   In order to support multiple feeds with different formats, data parsers and structs can be used to structure and filter raw input, and at the same time provide versatility to acceptable format for the raw input. A change in raw input format can only require code changes in the structs without touching the main processing pipeline.

   For example, if the current format of the data from the Odds Feed look like:

       raw = %{
                "name": "match-name"
                "kickOf": "kickoff-time"
                "outcomes": "outcomes"
             }

    We could have a function like ```FeedConsumer.Struct.OddMatch.parse(raw)``` that returns: 

        %FeedConsumer.Struct.OddMatch{name: "Name", kickoff: "AAA", outcomes: []}

    Knowing this standard format for OddMatch, we can then continue coding our program and use the above standardized keys :name, :kickoff, and :outcomes.

    In any case the odds' format change, we only need to change how FeedConsumer.Struct.OddMatch parses the raw input to return the same expected keys of :name, :kickoff, and :outcomes.

    With this, it won't matter much if the raw input format changes to:

       raw = %{
         "match-name": "match-name",
         "kickOf-at": "kickoff-time",
         "match-outcomes": "outcomes"
       }

      as long as FeedConsumer.Struct.OddMatch returns the same structure.
      
      Multiple feeds can also be handled by different processes that consume from the different respective feeds. Match schedule and other relevant data is saved in the ETS and is therefore centrally accessible to processes.


2. **What issues would you see arising with collecting odds from a feed similar to this?**

   Some of the possible issues include non-uniform formats, unexpected results, incomplete and/or inconsistent data, and endpoint timeout.

3. **When would you consider match odds invalid? And how would you keep track of this?**

   A match odd is considered invalid if it contains incomplete keys (i.e. "1", "x", or "2" is missing) or if there are extraneous keys present. Invalid match odds received are currently logged to a file for record.

4. **What to do if the feed and match schedule's team names differ, how could you get a good matching with some fuzziness?**

   To increase the match rate and provide good matching with fuzziness, the following were done:
   
   * **Save also a match info with the team names interchanged**
    
       Handles cases when the the Odds Feed has the team 1 and team 2 interchanged so that whatever order the teams are listed, a match can be found as long as it refers to the teams 1 and 2 playing.
       
   * **FeedConsumer.Substitution**
   
      Records known and/or observed team name equivalents. Guided by the knowledge that team names may differ between the Odds Feed and the Schedule API, equivalents could be recorded and be used when saving match data. Similae to bullet # 1, a copy of the match can be saved with the team's alternate name so that when it is the one used for querying, relevant data can still be found.
      
   * **Logging (Jaro Distance)**
   
      For team names not exactly matching any of the stored data, the closest team name (by Jaro distance) is logged if it is within the set threshold. With this, team name equivalents and conventions can be discovered and be added to the FeedConsumer.Substitutions. With this method, the equivalence of Darlington 1883 with Darlington FC was discovered.