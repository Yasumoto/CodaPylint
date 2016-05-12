//
//  Runner.m
//  CodaPylint
//
//  Created by Joe Smith on 5/11/16.
//  Copyright © 2016 Joe Smith. All rights reserved.
//

#import "Runner.h"

@interface Runner()

@property bool cancelled;
@property (strong, nonatomic) NSTask *task;

@end

@implementation Runner

@synthesize cancelled = _cancelled;
@synthesize task = _task;
@synthesize delegate = _delegate;

- (void) executeBinary:(NSString *)binary
                     atPath:(NSString *)path
              withArguments:(NSArray *)arguments {

    self.cancelled = false;

    self.task = [[NSTask alloc] init];
    [self.task setCurrentDirectoryPath:path];
    [self.task setLaunchPath:binary];
    [self.task setArguments:arguments];
    [self.task setStandardError:[NSPipe pipe]];
    [self.task setStandardOutput:[NSPipe pipe]];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(taskDidEnd:)
                                                 name:NSTaskDidTerminateNotification
                                               object:self.task];

    [self.task launch];

    while ( !self.cancelled && self.task.isRunning )
    {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
}

- (void) cancel {
    self.cancelled = true;
}

- (void)taskDidEnd:(NSNotification*)notification
{
    if (!self.cancelled) {
        NSString *output = [[NSString alloc] initWithData:[[[self.task standardOutput] fileHandleForReading] readDataToEndOfFile] encoding: NSUTF8StringEncoding];
        NSString *error = [[NSString alloc] initWithData:[[[self.task standardError] fileHandleForReading] readDataToEndOfFile] encoding: NSUTF8StringEncoding];
        [self.delegate executionComplete:output withError:error];
    }
}

@end
