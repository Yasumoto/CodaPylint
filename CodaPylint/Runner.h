//
//  Runner.h
//  CodaPylint
//
//  Created by Joe Smith on 5/11/16.
//  Copyright © 2016 Joe Smith. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RunnerDelegate <NSObject>

- (void) executionComplete:(NSString *)output withError:(NSString *)errorMessage;

@end

@interface Runner : NSObject

@property (strong, nonatomic) id<RunnerDelegate> delegate;

- (void) executeBinary:(NSString *)binary atPath:(NSString *)path withArguments:(NSArray *)arguments;
- (void) cancel;

@end