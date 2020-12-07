//
//  DDNetwork.m
//  ElectrocardiographSDK
//
//  Created by jiang xin on 2020/11/11.
//

#import "DDNetwork.h"

@implementation DDNetwork

+ (instancetype)shareInstance
{
    static DDNetwork *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[DDNetwork alloc] init];
        [_sharedInstance configure];
    });
    return _sharedInstance;
}

- (void)configure
{
    self.requestURL = @"https://wx.ahdms.top";
}

- (void)requestHTTPMethod:(NSString *)httpMenthod relativePath:(NSString *)relativePath params:(NSDictionary *)params successBlock:(HSResponseSuccessBlock)successBlock failBlock:(HSResponseFailBlock)failBlock
{

    NSMutableString *paramsString = [[NSMutableString alloc] initWithCapacity:0];
    for (int i=0;i<[params allKeys].count;i++) {
        NSString *key = [[params allKeys] objectAtIndex:i];
        [paramsString appendString:[NSString stringWithFormat:@"%@=%@",key,[params objectForKey:key]]];
        if (i < [params allKeys].count-1) {
            [paramsString appendString:@"&"];
        }
    }

    NSString *urlString = [NSString stringWithFormat:@"%@%@", self.requestURL, relativePath];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    request.HTTPMethod = httpMenthod;
    request.HTTPBody = [paramsString dataUsingEncoding:NSUTF8StringEncoding];
    NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        @try {
            if (!error) {
                NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                if (successBlock) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        successBlock(responseObject);
                    });
                }
            } else {
                if (failBlock) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        failBlock(error);
                    });
                }
            }
        } @catch (NSException *exception) {
            
        } @finally {
            
        }
        
    }];
    [dataTask resume];
}

- (void)requestGET:(NSString *)relativePath params:(NSDictionary *)params successBlock:(HSResponseSuccessBlock)successBlock failBlock:(HSResponseFailBlock)failBlock
{
    [self requestHTTPMethod:@"GET" relativePath:relativePath params:params successBlock:^(NSDictionary * _Nonnull responseObject) {
        if (successBlock) {
            return successBlock(responseObject);
        }
    } failBlock:^(NSError * _Nonnull error) {
        if (failBlock) {
            return failBlock(error);
        }
    }];
}

- (void)requestPOST:(NSString *)relativePath params:(NSDictionary *)params successBlock:(HSResponseSuccessBlock)successBlock failBlock:(HSResponseFailBlock)failBlock
{
    [self requestHTTPMethod:@"POST" relativePath:relativePath params:params successBlock:^(NSDictionary * _Nonnull responseObject) {
        if (successBlock) {
            return successBlock(responseObject);
        }
    } failBlock:^(NSError * _Nonnull error) {
        if (failBlock) {
            return failBlock(error);
        }
    }];
}

- (void)requestJsonPost:(NSString *)relativePath params:(NSDictionary *)params successBlock:(HSResponseSuccessBlock)successBlock failBlock:(HSResponseFailBlock)failBlock
{
    NSString *urlString = [NSString stringWithFormat:@"%@%@", self.requestURL, relativePath];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:nil];
    [request addValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];

    NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            if (successBlock) {
                NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                successBlock(responseObject);
            }
        } else {
            if (failBlock) {
                failBlock(error);
            }
        }
    }];
    [dataTask resume];
}

@end
