//
//  RMAnnotation.m
//  MapView
//
// Copyright (c) 2008-2009, Route-Me Contributors
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice, this
//   list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#import "RMAnnotation.h"
#import "RMMapView.h"
#import "RMMapLayer.h"
#import "RMMercatorToScreenProjection.h"

@implementation RMAnnotation

@synthesize coordinate;
@synthesize title;
@synthesize userInfo;
@synthesize annotationType;
@synthesize annotationIcon;
@synthesize anchorPoint;

@synthesize mapView;
@synthesize projectedLocation;
@synthesize projectedBoundingBox;
@synthesize hasBoundingBox;
@synthesize position;
@synthesize layer;

+ (id)annotationWithMapView:(RMMapView *)aMapView coordinate:(CLLocationCoordinate2D)aCoordinate andTitle:(NSString *)aTitle
{
    return [[[self alloc] initWithMapView:aMapView coordinate:aCoordinate andTitle:aTitle] autorelease];
}

- (id)initWithMapView:(RMMapView *)aMapView coordinate:(CLLocationCoordinate2D)aCoordinate andTitle:(NSString *)aTitle
{
    if (!(self = [super init]))
        return nil;

    self.mapView    = aMapView;
    self.coordinate = aCoordinate;
    self.title      = aTitle;
    self.userInfo   = nil;
    self.layer      = nil;

    self.annotationType = nil;
    self.annotationIcon = nil;
    self.anchorPoint    = CGPointZero;
    self.hasBoundingBox = NO;

    return self;
}

- (void)dealloc
{
    self.title    = nil;
    self.userInfo = nil;
    self.mapView  = nil;
    self.layer    = nil;
    self.annotationType = nil;
    self.annotationIcon = nil;

    [super dealloc];
}

- (void)setCoordinate:(CLLocationCoordinate2D)aCoordinate
{
    coordinate = aCoordinate;
    self.projectedLocation = [[mapView projection] coordinateToProjectedPoint:aCoordinate];
    self.position = [[mapView mercatorToScreenProjection] projectProjectedPoint:self.projectedLocation];
}

- (void)setBoundingBoxCoordinatesSouthWest:(CLLocationCoordinate2D)southWest northEast:(CLLocationCoordinate2D)northEast
{
    RMProjectedPoint first = [[mapView projection] coordinateToProjectedPoint:southWest];
    RMProjectedPoint second = [[mapView projection] coordinateToProjectedPoint:northEast];
    self.projectedBoundingBox = RMMakeProjectedRect(first.easting, first.northing, second.easting - first.easting, second.northing - first.northing);
    self.hasBoundingBox = YES;
}

- (void)setMapView:(RMMapView *)aMapView
{
    mapView = aMapView;
    if (!aMapView) {
        self.layer = nil;
    }
}

- (void)setPosition:(CGPoint)aPosition
{
    position = aPosition;
    if (layer) {
        layer.position = aPosition;
    }
}

- (void)setLayer:(RMMapLayer *)aLayer
{
    if (layer != aLayer) {
        [layer removeFromSuperlayer]; [layer release];
        layer = [aLayer retain];
        layer.annotation = self;
    }
    layer.position = self.position;
}

- (BOOL)isAnnotationWithinBounds:(CGRect)bounds
{
    if (self.hasBoundingBox) {
        RMProjectedRect projectedScreenBounds = [[mapView mercatorToScreenProjection] projectedBounds];
        return RMProjectedRectInterectsProjectedRect(projectedScreenBounds, projectedBoundingBox);
    } else {
        return CGRectContainsPoint(bounds, self.position);
    }
}

- (BOOL)isAnnotationOnScreen
{
    CGRect screenBounds = [[mapView mercatorToScreenProjection] screenBounds];
    return [self isAnnotationWithinBounds:screenBounds];
}

- (NSString *)description
{
    if (self.hasBoundingBox)
        return [NSString stringWithFormat:@"<%@: %@ @ (%.0f,%.0f) {(%.0f,%.0f) - (%.0f,%.0f)}>", NSStringFromClass([self class]), self.title, self.projectedLocation.easting, self.projectedLocation.northing, self.projectedBoundingBox.origin.easting, self.projectedBoundingBox.origin.northing, self.projectedBoundingBox.origin.easting + self.projectedBoundingBox.size.width, self.projectedBoundingBox.origin.northing + self.projectedBoundingBox.size.height];
    else
        return [NSString stringWithFormat:@"<%@: %@ @ (%.0f,%.0f)>", NSStringFromClass([self class]), self.title, self.projectedLocation.easting, self.projectedLocation.northing];
}

@end
