//
//  ViewController.m
//  weather_app
//
//  Created by Justin on 3/15/19.
//  Copyright © 2019 Justin. All rights reserved.
//

#import "ViewController.h"
#import "WeatherTableViewCell.h"
#import "NSString+Common.h"

@implementation ViewController {
    NSMutableArray *_tableData;
    NSDateFormatter *_dateFormatter;
    NSDateFormatter *_weatherDateFormatter;
    NSString *_location;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    _tableData = [NSMutableArray new];
    
    self.forecastList.dataSource = self;
    self.forecastList.delegate = self;
    self.forecastList.layer.cornerRadius = 10;
    
    self.submitButton.layer.cornerRadius = 5;
    
    _dateFormatter = [NSDateFormatter new];
    _dateFormatter.dateFormat = @"MMMM d, h:mm a";
    
    _weatherDateFormatter = [NSDateFormatter new];
    _weatherDateFormatter.dateFormat = @"EEEE, MMM d";
    
    _location = [@"seattle" sentenceCapitalizedString];
    
    [NSTimer scheduledTimerWithTimeInterval:10.0
                                     target:self
                                   selector:@selector(updateDate)
                                   userInfo:nil
                                    repeats:YES];
    
    [NSTimer scheduledTimerWithTimeInterval:30.0
                                     target:self
                                   selector:@selector(fetchCurrentWeather)
                                   userInfo:nil
                                    repeats:YES];
    
    [self updateDate];
    [self fetchForecast];
    [self fetchCurrentWeather];

    self.cityLabel.text = _location;
}


- (IBAction)submit:(id)sender {
    [self.textInput resignFirstResponder];
    _location = [[self.textInput text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    self.cityLabel.text = [_location sentenceCapitalizedString];
    self.textInput.text = @"";
    [self fetchCurrentWeather];
    [self fetchForecast];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *weatherTableViewCell = @"WeatherTableViewCell";
    
    WeatherTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:weatherTableViewCell];

    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:weatherTableViewCell owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    
    NSDictionary *dataItem = [_tableData objectAtIndex:indexPath.row];
    
    if(dataItem == nil) return cell;
    
    cell.dateLabel.text = [dataItem objectForKey:@"date"];
    cell.descriptionLabel.text = [[dataItem objectForKey:@"description"] sentenceCapitalizedString];
    cell.maxLabel.text = [dataItem objectForKey:@"max"];
    cell.minLabel.text =[dataItem objectForKey:@"min"];
    cell.image.image = [UIImage imageNamed:[dataItem objectForKey:@"icon"]];

    return cell;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.textInput resignFirstResponder];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_tableData count];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 70;
}

-(void)updateDate {
    self.dateLabel.text = [_dateFormatter stringFromDate:[NSDate new]];
}

-(void)fetchForecast {
    NSString *url = [self assembleRequestUrl:@"forecast/daily"];

    [self fetchWeather:url withHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (data != nil) [self parseForecastJSON:data];
    }];
}

-(void)fetchCurrentWeather {
    NSString *url = [self assembleRequestUrl:@"weather"];
    
    [self fetchWeather:url withHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (data != nil) [self parseWeatherJSON:data];
    }];
}

-(void)fetchWeather:(NSString *)url withHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    [request setURL:[NSURL URLWithString:url]];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler: completionHandler];
    [task resume];
}

-(NSString *) assembleRequestUrl:(NSString *) requestType{
    NSString *additionalQueryParams = @"&mode=json&appid=c36043dd046f0d256302ccfa30d8c6ad&units=imperial";
    return [NSString stringWithFormat:@"https://api.openweathermap.org/data/2.5/%@?q=%@%@", requestType, _location, additionalQueryParams];
}

-(void) parseForecastJSON:(NSData *) jsonData {
    NSError *error = nil;

    id object = [NSJSONSerialization
                 JSONObjectWithData:jsonData
                 options:0
                 error:&error];
    
    if ([object isKindOfClass:[NSDictionary class]]) {
        NSArray *forecast = [object valueForKey:@"list"];
        NSMutableArray *tableData = [NSMutableArray new];

        for(id item in forecast) {
            NSNumber *time = [item valueForKey:@"dt"];
            NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:time.doubleValue];
            NSString *formattedDate = [_weatherDateFormatter stringFromDate:date];

            NSDictionary *weather = [item valueForKey:@"weather"][0];
            NSMutableString *description = [weather valueForKey:@"description"];
            
            NSDictionary *temp = [item valueForKey:@"temp"];

            NSString *max = [NSString stringWithFormat:@"%dº", [[temp objectForKey:@"max"] intValue]];
            NSString *min = [NSString stringWithFormat:@"%dº", [[temp objectForKey:@"min"] intValue]];
            
            NSString *icon = [self getImageNameForCode:[weather objectForKey:@"icon"]];
            
            NSDictionary *weatherData = @{
                                          @"date": formattedDate,
                                          @"description": [description sentenceCapitalizedString],
                                          @"max": max,
                                          @"min": min,
                                          @"icon": icon
                                          };
            
            [tableData addObject:weatherData];
        }
        
        _tableData = tableData;
        [self.forecastList performSelectorOnMainThread:@selector(reloadData)
                                            withObject:nil
                                         waitUntilDone:NO];
    }
}

-(void) parseWeatherJSON:(NSData *) jsonData {
    NSError *error = nil;

    id object = [NSJSONSerialization
                 JSONObjectWithData:jsonData
                 options:0
                 error:&error];
    
    NSDictionary *main = [object valueForKey:@"main"];
    
    NSString *max = [NSString stringWithFormat:@"%d", [[main valueForKey:@"temp_max"] intValue]];
    NSString *min = [NSString stringWithFormat:@"%d", [[main valueForKey:@"temp_min"] intValue]];
    NSString *current = [NSString stringWithFormat:@"%d", [[main valueForKey:@"temp"] intValue]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.minMaxLabel.text = [NSString stringWithFormat:@"Min %@º | Max %@º", min, max];
        self.tempLabel.text = [NSString stringWithFormat:@"%dºF", [current intValue]];
    });
    
}

-(NSString *)getImageNameForCode: (NSString*) code {
    if([code isEqualToString:@"01n"]) {
        return @"sunny";
    } else if ([code isEqualToString:@"02d"]) {
        return @"partly-sunny";
    } else if ([code isEqualToString:@"02d"]) {
        return @"partly-sunny";
    } else if ([code isEqualToString:@"03d"]) {
        return @"partly-sunny";
    } else if ([code isEqualToString:@"04d"]) {
        return @"partly-sunny";
    } else if ([code isEqualToString:@"02n"]) {
        return @"partly-cloudy-moon";
    } else if ([code isEqualToString:@"03n"]) {
        return @"partly-cloudy-moon";
    } else if ([code isEqualToString:@"04n"]) {
        return @"partly-cloudy-moon";
    } else if ([code isEqualToString:@"10d"]) {
        return @"drizzle";
    } else if ([code isEqualToString:@"09d"]) {
        return @"heavy-rain";
    } else if ([code isEqualToString:@"02d"]) {
        return @"partly-sunny";
    } else if ([code isEqualToString:@"13d"]) {
        return @"heavy-snow";
    } else if ([code isEqualToString:@"11d"]) {
        return @"lightning";
    } else if ([code isEqualToString:@"01d"]) {
        return @"sunny";
    } else {
        return @"thermometer";
    }
}

@end
