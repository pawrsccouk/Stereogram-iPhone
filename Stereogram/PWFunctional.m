//
//  PWFunctional.m
//  CharSheet
//
//  Created by Patrick Wallace on 13/12/2012.
//
//

#import "PWFunctional.h"

@implementation NSArray (ArraySimplifiers)

-(NSArray *)filteredArrayUsingBlock:(PWArraySimpleBlockPredicate)block
{
    return [self filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
        return block(object);
    }]];
}


-(NSArray *)transformedArrayUsingBlock:(PWArrayTransformBlock)block
{
    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:self.count];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) { results[idx] = block(obj); }];
    return results;
}

-(NSArray *)transformedArrayAsyncUsingBlock:(PWArrayTransformBlock)block
{
        // Transform the array in parallel if possible.
    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:self.count];
    [self enumerateObjectsWithOptions:NSEnumerationConcurrent
                           usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                   // The call to block() is not synchronised, so the block code should be able to run in parallel.
                               id result = block(obj);
                               @synchronized(results) {
                                   results[idx] = result;
                               }
                           }];
    return results;
}



-(id)reducedArrayUsingBlock:(PWArrayReduceBlock)block
{
    if(self.count == 0) return nil;
    
    id p = [self objectAtIndex:0];
    for(NSInteger i = 1, c = self.count; i < c; ++i)
        p = block(p, [self objectAtIndex:i]);
    return p;
}

-(id)reducedArrayUsingBlock:(PWArrayReduceBlock)block startingValue:(id)value
{
    id p = value;
    for(id i in self)
        p = block(p, i);
    return p;
}

@end

