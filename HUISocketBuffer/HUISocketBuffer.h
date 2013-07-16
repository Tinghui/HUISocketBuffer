//
//  HUISocketBuffer.h
//  HUISocketBuffer
//
//  Created by ZhangTinghui on 13-7-16.
//  Copyright (c) 2013年 ZhangTinghui. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark - <HUISocketBufferQueuing>
@class HUISocketBuffer;
@protocol HUISocketBufferQueuing <NSObject>

@optional
- (id)dequeuedFromHUISocketBufferQueuing:(HUISocketBuffer *)buffer;
- (HUISocketBuffer *)enqueuedHUISocketBuffer;

@end






@interface HUISocketBuffer : NSObject

/**********************************
 *  Create Buffer
 **********************************/
#pragma mark - Create Buffer
+ (id)buffer;
+ (id)bufferWithData:(NSData *)data;
+ (id)bufferWithBytes:(const void*)bytes withLength:(NSUInteger)bytesLength;

- (id)init;
- (id)initWithData:(NSData *)data;
- (id)initWithBytes:(const void*)bytes withLength:(NSUInteger)bytesLength;


/**********************************
 *  Buffer Data
 **********************************/
#pragma mark - Buffer Data
- (NSData *)bufferData;     //  Get data in buffer
- (void)cleanBufferData;    //  Clean data in buffer


/**********************************
 *  Dequeue/Enqueue data.
 *  1. For enqueue, the buffer always assumes the enqueued data is in host byte order and will convert it to network byte order if neened.
 *  2. For dequeue, the buffer always assumes the data in buffer is in network byte order and will dequeue it to host byte order if neened.
 **********************************/
#pragma mark - Dequeue/Enqueue
#pragma mark Basic Dequeue/Enqueue Methods
- (void)dequeueToBuffer:(void *)buffer withLength:(NSUInteger)bufferLength;
- (void)enqueueBytes:(const void *)bytes withLength:(NSUInteger)bytesLength;

- (Byte)dequeueByte;
- (void)enqueueByte:(Byte)byte;

- (UInt16)dequeueUInt16;
- (void)enqueueUInt16:(UInt16)hostUInt16;

- (UInt32)dequeueUInt32;
- (void)enqueueUInt32:(UInt32)hostUInt32;

- (UInt64)dequeueUInt64;
- (void)enqueueUInt64:(UInt64)hostUInt64;

#pragma mark Advanced Dequeue Methods
- (NSData *)dequeueDataWithLength:(NSUInteger)bytesLength;
- (NSData *)dequeueDataUntilSeperator:(Byte)seperator;  // automatically drop seperator
- (NSData *)dequeueDataUntilSeperator:(Byte)seperator dropSeperator:(BOOL)drop;

- (NSString *)dequeueUTF8StringWithLength:(NSUInteger)bytesLength;
- (NSString *)dequeueStringWithLength:(NSUInteger)bytesLength encoding:(NSStringEncoding)encoding;

- (NSString *)dequeueUTF8StringUntilSeperator:(Byte)seperator;  // automatically drop seperator
- (NSString *)dequeueStringUntilSeperator:(Byte)seperator withEncoding:(NSStringEncoding)encoding;  // automatically drop seperator
- (NSString *)dequeueStringUntilSeperator:(Byte)seperator withEncoding:(NSStringEncoding)encoding dropSeperator:(BOOL)drop;

@end

