//
//  DDNetwork.h
//  ElectrocardiographSDK
//
//  Created by jiang xin on 2020/11/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DDNetwork : NSObject

+ (instancetype)shareInstance;

//请求URL
@property (nonatomic, copy) NSString *requestURL;

typedef void(^HSResponseSuccessBlock)(NSDictionary *responseObject);

typedef void(^HSResponseFailBlock)(NSError *error);

/**
 * @brief   GET请求方法
 * @author  yuancan

 * @param relativePath 接口名称
 * @param params 请求参数
 * @param successBlock 请求成功回调
 * @param failBlock 请求失败回调
 */
- (void)requestGET:(NSString *)relativePath params:(NSDictionary *)params successBlock:(HSResponseSuccessBlock)successBlock failBlock:(HSResponseFailBlock)failBlock;

/**
 * @brief   POST请求方法
 * @author  yuancan

 * @param relativePath 接口名称
 * @param params 请求参数
 * @param successBlock 请求成功回调
 * @param failBlock 请求失败回调
 */
- (void)requestPOST:(NSString *)relativePath params:(NSDictionary *)params successBlock:(HSResponseSuccessBlock)successBlock failBlock:(HSResponseFailBlock)failBlock;

/**
 * @brief   JSON格式网络接口请求方法
 * @author  yuancan
 *
 * @param relativePath 接口名称
 * @param params 请求参数
 * @param successBlock 请求成功回调
 * @param failBlock 请求失败回调
 */
- (void)requestJsonPost:(NSString *)relativePath params:(NSDictionary *)params successBlock:(HSResponseSuccessBlock)successBlock failBlock:(HSResponseFailBlock)failBlock;


@end

NS_ASSUME_NONNULL_END
