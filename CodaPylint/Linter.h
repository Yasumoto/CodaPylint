//
//  Linter.h
//  CodaPylint
//
//  Created by Joseph Mehdi Smith on 5/11/16.
//  Copyright © 2016 Joe Smith. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CodaPluginsController.h"
#import "Runner.h"

@interface Linter : NSObject <CodaValidator, RunnerDelegate>

@property (nonatomic, strong) NSString *filePath;

@end
