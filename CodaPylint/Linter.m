//
//  Linter.m
//  CodaPylint
//
//  Created by Joseph Mehdi Smith on 5/11/16.
//  Copyright © 2016 Joe Smith. All rights reserved.
//

#import "Linter.h"

@interface Linter()

@property (nonatomic, strong) Runner* runner;
@property (nonatomic, strong) id<CodaValidatorDelegate> validatorDelegate;

@end

@implementation Linter

@synthesize runner = _runner;
@synthesize filePath = _filePath;
@synthesize validatorDelegate = _validatorDelegate;

//TODO(jmsmith): Fix this
NSString *pylintPath = @"/Users/jmsmith/workspace/chef-repo/.virtualenv/bin/pylint";
NSString *errorDomain = @"com.bjoli.CodaPylint.ErrorDomainLinter";

/**
 Starts validation.

 This is the primary validation method, it will be called on a secondary thread.
 */

- (void)validate {
    self.runner = [[Runner alloc] init];
    self.runner.delegate = self;
    [self.runner executeBinary:pylintPath atPath:@"/Users/jmsmith/workspace/chef-repo" withArguments:@[@"--output-format=text", self.filePath]];
}


/**
 Cancels validation.

 The validator should end validation and do whatever clean-up is necessary.
 */

- (void)cancel {

}


/**
 Returns a human-readable name of the syntax being validated.
 */

- (NSString*)name {
    return @"Python";
}


/**
 Sets the validator delegate.
 @param delegate Opaque object which conforms to the CodaValidatorDelegate protocol, may be nil.
 */

- (void)setDelegate:(id<CodaValidatorDelegate>)delegate {
    self.validatorDelegate = delegate;
}


/**
 Return the validator delegate object.
 */

- (id<CodaValidatorDelegate>)delegate {
    return self.validatorDelegate;
    
}


// Runner Delegate
- (void) executionComplete:(NSString *)output withError:(NSString *)errorMessage {

    NSError *error = nil;
    if (errorMessage.length > 0) {
        NSString *desc = NSLocalizedString(errorMessage, @"");
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : desc };
        error = [NSError errorWithDomain:errorDomain
                                    code:-101
                                userInfo:userInfo];
    }

    NSArray *results = [self calculateResults:output];
    [self.delegate validator:self didComplete:results error:nil];
}

- (NSArray *) calculateResults:(NSString *) output {
    NSArray *lines = [output componentsSeparatedByString:@"\n"];
    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:lines.count];
    for (NSString *line in lines) {
        if (line.length > 0 && [@[@"I", @"C", @"W", @"E", @"R"] indexOfObject:[line substringToIndex:1]] != NSNotFound) {
            NSMutableCharacterSet *whitespaceAndPunctuationSet = [NSMutableCharacterSet punctuationCharacterSet];
            NSScanner *scanner = [NSScanner scannerWithString:line];
            scanner.charactersToBeSkipped = whitespaceAndPunctuationSet;
            NSString *lintWarningType;
            [scanner scanUpToCharactersFromSet:whitespaceAndPunctuationSet intoString:&lintWarningType];
            // Just a warning, or an error
            NSString *error = kValidatorTypeWarning;
            if ([@"E" isEqualToString:[line substringToIndex:1]]) {
                error = kValidatorTypeError;
            }

            NSString *lineNumber;
            [scanner scanUpToCharactersFromSet:whitespaceAndPunctuationSet intoString:&lineNumber];
            [lineNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
            lineNumber = [lineNumber stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];

            NSString *columnNumber;
            [scanner scanUpToCharactersFromSet:whitespaceAndPunctuationSet intoString:&columnNumber];
            columnNumber = [columnNumber stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];


            NSString *verbose;
            [scanner scanUpToString:@"(" intoString:&verbose];
            [scanner scanString:@"(" intoString:nil];
            verbose = [verbose stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];


            NSString *errorId;
            [scanner scanUpToString:@")" intoString:&errorId];
            [scanner scanUpToString:@"(" intoString:nil];
            NSString *shortDescription;
            [scanner scanUpToString:@")" intoString:&shortDescription];
            NSString *key = @"";
            if (shortDescription == nil) {
                key = [NSString stringWithFormat:@"%@", errorId];
            } else {
                key = [NSString stringWithFormat:@"%@: %@", errorId, shortDescription];
            }


            NSDictionary *lintedError = @{kValidatorMessageStringKey: key,
                                          kValidatorExplanationStringKey: [NSString stringWithFormat:@"%@", verbose],
                                          kValidatorColumnKey: [[NSNumber alloc] initWithLong:columnNumber.integerValue],
                                          kValidatorLineKey: [[NSNumber alloc] initWithLong:lineNumber.integerValue],
                                          kValidatorErrorTypeKey: error};
            [results addObject:lintedError];

        }
    }
    return results;
}

@end
