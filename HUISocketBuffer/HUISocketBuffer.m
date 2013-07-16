//
//  HUISocketBuffer.m
//  HUISocketBuffer
//
//  Created by ZhangTinghui on 13-7-16.
//  Copyright (c) 2013年 ZhangTinghui. All rights reserved.
//

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "HUISocketBuffer.h"


#define ntohll(x) ( ( (UInt64)(ntohl( (UInt32)(((x) << 32) >> 32) )) << 32) | ntohl( ((UInt32)((x) >> 32)) ) )
#define htonll(x) ntohll(x)

#define kBufferBlockSize 256   //in bytes

@implementation HUISocketBuffer
{
    void    *_buffer;           // The pointer of buffer's header
    size_t  _totalSize;         // The total size of buffer
    size_t  _dequeuedPosition;  // The dequeued position in buffer (offset from buffer's header)
    size_t  _enqueuedPosition;  // The enqueued position in buffer (offset from buffer's header)
}

- (void)dealloc
{
    if (_buffer != NULL)
        free(_buffer);
    _buffer = NULL;
}

#pragma mark - Create Buffer
+ (id)buffer
{
    return [[self alloc] init];
}

+ (id)bufferWithData:(NSData *)data
{
    return [[self alloc] initWithData:data];
}

+ (id)bufferWithBytes:(const void*)bytes withLength:(NSUInteger)bytesLength
{
    return [[self alloc] initWithBytes:bytes withLength:bytesLength];
}

- (id)init
{
    self = [super init];
    if (self == nil)
        return nil;
    
    [self _mallocBufferWithSize:kBufferBlockSize];
    return self;
}

- (id)initWithData:(NSData *)data
{
    return [self initWithBytes:[data bytes] withLength:[data length]];
}

- (id)initWithBytes:(const void*)bytes withLength:(NSUInteger)bytesLength
{
    self = [super init];
    if (self == nil)
        return nil;
    
    [self _mallocBufferWithSize:bytesLength];
    memcpy(_buffer, bytes, bytesLength);
    _enqueuedPosition = bytesLength;
    return self;
}

#pragma mark - Buffer Management
- (void *)_allocatedMemoryWithSize:(NSUInteger)size failedReason:(NSString *)reason
{
    if (size == 0)
        return NULL;
    
    void *memory = malloc(size);
    if (memory == NULL)
        @throw [NSException exceptionWithName:NSMallocException reason:reason userInfo:nil];
    
    return memory;
}

- (void)_mallocBufferWithSize:(NSUInteger)size
{
    @synchronized(self)
    {
        NSAssert((_buffer == NULL && _totalSize <= 0), @"_buffer is not NULL can't init again");
        
        _buffer = [self _allocatedMemoryWithSize:size failedReason:@"can't malloc memory for _buffer"];
        if (_buffer == NULL)
            return;
        
        _totalSize = size;
        _enqueuedPosition = 0;
        _dequeuedPosition = 0;
        memset(_buffer, 0, _totalSize);
    }
}

- (void)_freeBuffer
{
    @synchronized(self)
    {
        if (_buffer == NULL)
            return;
        
        _totalSize = 0;
        _enqueuedPosition = 0;
        _dequeuedPosition = 0;
        free(_buffer);
        _buffer = NULL;
    }
}

// Expand buffer by kNetDataBufferBlockSize size
- (void)_expandBuffer
{
    _buffer = realloc(_buffer, _totalSize + kBufferBlockSize);
    if (_buffer == NULL)
        @throw [NSException exceptionWithName:NSMallocException reason:@"_buffer expand failed" userInfo:nil];
    else
        _totalSize += kBufferBlockSize;
}

// Drop buffer before dequeued position
- (void)_dropDequeuedBuffer
{
    if (_dequeuedPosition <= 0)
        return;
    
    NSInteger newBufferSize = _enqueuedPosition - _dequeuedPosition;
    if (newBufferSize <= 0)
        return;
    
    void *newBuffer = malloc(newBufferSize);
    if (newBuffer == NULL)
        return;
    
    memcpy(newBuffer, _buffer + _dequeuedPosition, newBufferSize);
    free(_buffer);
    _buffer = newBuffer;
    _totalSize = newBufferSize;
    _dequeuedPosition = 0;
    _enqueuedPosition = _totalSize;
}

// Drop buffer before dequeued position if dequeued length is bigger than kBufferBlockSize
- (void)_dropDequeuedBufferIfNeeded
{
    if (_dequeuedPosition < kBufferBlockSize)
        return;
    
    [self _dropDequeuedBuffer];
}

- (NSData *)bufferData
{
    NSInteger dataSize = _enqueuedPosition - _dequeuedPosition;
    
    if (dataSize <= 0)
        return nil;
    
    return [[NSData alloc] initWithBytes:_buffer + _dequeuedPosition
                                  length:dataSize];
}

//clean the buffer to a new buffer
- (void)cleanBufferData
{
    [self _freeBuffer];
    [self _mallocBufferWithSize:kBufferBlockSize];
}

#pragma mark - Enqueue/Dequeue
#pragma mark Basic Dequeue/Enqueue Methods
- (BOOL)_canDequeueWithSize:(NSUInteger)dequeueSize
{
    if (_dequeuedPosition + dequeueSize > _enqueuedPosition)
    {
        @throw [NSException exceptionWithName:NSRangeException
                                       reason:@"buffer will be dequeued over range"
                                     userInfo:nil];
        return NO;
    }
    
    return YES;
}

- (void)dequeueToBuffer:(void *)buffer withLength:(NSUInteger)bufferLength
{
    if (![self _canDequeueWithSize:bufferLength])
        return;
    
    memcpy(buffer, _buffer + _dequeuedPosition, bufferLength);
    _dequeuedPosition += bufferLength;
    
    [self _dropDequeuedBufferIfNeeded];
}

- (void)enqueueBytes:(const void *)bytes withLength:(NSUInteger)bytesLength
{
    if (bytesLength + _enqueuedPosition >= _totalSize)
        [self _expandBuffer];
    
    memcpy(_buffer + _enqueuedPosition, bytes, bytesLength);
    _enqueuedPosition += bytesLength;
}

- (Byte)dequeueByte
{
    Byte value;
    [self dequeueToBuffer:&value withLength:sizeof(Byte)];
    return value;
}

- (void)enqueueByte:(Byte)byte
{
    [self enqueueBytes:&byte withLength:sizeof(byte)];
}

- (UInt16)dequeueUInt16
{
    UInt16 value;
    [self dequeueToBuffer:&value withLength:sizeof(UInt16)];
    return ntohs(value);
}

- (void)enqueueUInt16:(UInt16)hostUInt16
{
    UInt16 netOrderValue = htons(hostUInt16);
    [self enqueueBytes:&netOrderValue withLength:sizeof(UInt16)];
}

- (UInt32)dequeueUInt32
{
    UInt32 value;
    [self dequeueToBuffer:&value withLength:sizeof(UInt32)];
    return ntohl(value);
}

- (void)enqueueUInt32:(UInt32)hostUInt32
{
    UInt32 netOrderValue = htonl(hostUInt32);
    [self enqueueBytes:&netOrderValue withLength:sizeof(UInt32)];
}

- (UInt64)dequeueUInt64
{
    UInt64 value;
    [self dequeueToBuffer:&value withLength:sizeof(UInt64)];
    return ntohll(value);
}

- (void)enqueueUInt64:(UInt64)hostUInt64
{
    UInt64 netOrderValue = htonll(hostUInt64);
    [self enqueueBytes:&netOrderValue withLength:sizeof(UInt64)];
}

#pragma mark Advanced Dequeue Methods
- (NSUInteger)_dequeuedSizeUntilSeperator:(Byte)seperator
{
    NSUInteger dequeuedSize = 0;
    for (NSUInteger i = _dequeuedPosition; i < _enqueuedPosition; i++)
    {
        if ( *((Byte*)(_buffer + i)) == seperator)
            break;
        
        dequeuedSize++;
    }
    
    return dequeuedSize;
}

- (NSData *)dequeueDataWithLength:(NSUInteger)bytesLength
{
    
    if (bytesLength == 0)
        return nil;
    
    if (![self _canDequeueWithSize:bytesLength])
        return nil;
    
    NSMutableData *data = [[NSMutableData alloc] initWithBytes:_buffer+_dequeuedPosition
                                                        length:bytesLength];
    _dequeuedPosition += bytesLength;
    [self _dropDequeuedBufferIfNeeded];
    
    return data;
}

- (NSData *)dequeueDataUntilSeperator:(Byte)seperator dropSeperator:(BOOL)drop
{
    NSUInteger dequeuedSize = [self _dequeuedSizeUntilSeperator:seperator];
    
    NSData *decodedData = (dequeuedSize <= 0)? nil: [self dequeueDataWithLength:dequeuedSize];
    if ( drop && (_dequeuedPosition < _enqueuedPosition) )
        [self dequeueByte]; //if the seperator exists in buffer and need drop, drop it.
    
    return decodedData;
}

- (NSData *)dequeueDataUntilSeperator:(Byte)seperator
{
    return [self dequeueDataUntilSeperator:seperator dropSeperator:YES];
}

- (NSString *)dequeueStringWithLength:(NSUInteger)bytesLength encoding:(NSStringEncoding)encoding
{
    if (bytesLength == 0)
        return nil;
    
    void *chars = [self _allocatedMemoryWithSize:bytesLength + 1 failedReason:@"failed malloc memory for dequeue string"];
    memset(chars, 0, bytesLength + 1);
    [self dequeueToBuffer:chars withLength:bytesLength];
    
    NSString *string = [[NSString stringWithCString:chars encoding:encoding] copy];
    free(chars);
    
    return string;
}

- (NSString *)dequeueUTF8StringWithLength:(NSUInteger)bytesLength
{
    return [self dequeueStringWithLength:bytesLength encoding:NSUTF8StringEncoding];
}

- (NSString *)dequeueStringUntilSeperator:(Byte)seperator withEncoding:(NSStringEncoding)encoding dropSeperator:(BOOL)drop
{
    NSUInteger dequeuedSize = [self _dequeuedSizeUntilSeperator:seperator];
    
    NSString *string = (dequeuedSize <= 0)? nil: [self dequeueStringWithLength:dequeuedSize encoding:encoding];
    if ( drop && (_dequeuedPosition < _enqueuedPosition) )
        [self dequeueByte];
    
    return string;
}

- (NSString *)dequeueStringUntilSeperator:(Byte)seperator withEncoding:(NSStringEncoding)encoding
{
    return [self dequeueStringUntilSeperator:seperator withEncoding:encoding dropSeperator:YES];
}

- (NSString *)dequeueUTF8StringUntilSeperator:(Byte)seperator
{
    return [self dequeueStringUntilSeperator:seperator withEncoding:NSUTF8StringEncoding dropSeperator:YES];
}

@end
