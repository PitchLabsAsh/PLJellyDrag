//
//  ViewController.m
//  PLJellyDrag
//
//  Created by Ash Thwaites on 03/12/2015.
//  Copyright © 2015 Pitch. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
{
    UIView *dragView;
    UIView *bounceView;
    
    CGPoint panStartPoint;
    CGFloat value;
    UIDynamicAnimator *animator;
    UIAttachmentBehavior *slidingBehaviour;
    UIAttachmentBehavior *attachBehaviour;
    CADisplayLink *displayLink;
    CAShapeLayer *curveLayer;
}

@property (weak, nonatomic) IBOutlet UIView *jellyDragView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // create a debug view we can use to display the drag point
    dragView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    dragView.backgroundColor = [UIColor blueColor];
    dragView.center = self.jellyDragView.center;
    [self.jellyDragView addSubview:dragView];

    bounceView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    bounceView.backgroundColor = [UIColor redColor];
    bounceView.center = self.jellyDragView.center;
    [self.jellyDragView addSubview:bounceView];

    
    animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.jellyDragView];

    attachBehaviour = [[UIAttachmentBehavior alloc] initWithItem:bounceView attachedToAnchor:dragView.center];
    attachBehaviour.damping = 0.1;
    attachBehaviour.length =0;
    attachBehaviour.frequency = 3;
    [animator addBehavior:attachBehaviour];
    
    CGVector axis = CGVectorMake(0, 1);
    slidingBehaviour = [UIAttachmentBehavior slidingAttachmentWithItem:bounceView attachmentAnchor:self.jellyDragView.center axisOfTranslation:axis];
    [animator addBehavior:slidingBehaviour];
  
    UICollisionBehavior* collisionBehavior = [[UICollisionBehavior alloc] initWithItems:@[bounceView]];
    collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
    [animator addBehavior:collisionBehavior];

    
    displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(redraw)];
    [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];

    curveLayer = [CAShapeLayer layer];
    curveLayer.path = [self getViewPath].CGPath;
    curveLayer.fillColor = [UIColor yellowColor].CGColor;
    [self.jellyDragView.layer addSublayer:curveLayer];
    
    // create the pan gesture
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handlePanGesture:)];
    [self.jellyDragView addGestureRecognizer:panGesture];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidLayoutSubviews
{
    dragView.center = CGPointMake(self.jellyDragView.bounds.size.width/2,dragView.center.y);
    slidingBehaviour.anchorPoint = self.jellyDragView.center;
    attachBehaviour.anchorPoint = dragView.center;
}

// we need to track the initial touch point as we dont get a start point from a drag gesture
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint locationPoint = [[touches anyObject] locationInView:self.view];
    CGPoint viewPoint = [self.jellyDragView convertPoint:locationPoint fromView:self.view];
    
    if([self.jellyDragView pointInside:viewPoint withEvent:event])
    {
        // lets immediatly move the drag view
        panStartPoint = viewPoint;
    }
}

-(void)redraw
{
    curveLayer.path = [self getViewPath].CGPath;
}


- (UIBezierPath *) getViewPath {
    UIBezierPath *bPath = [UIBezierPath bezierPath];
    CGFloat width = self.jellyDragView.bounds.size.width;
    CGFloat height = self.jellyDragView.bounds.size.height;
    CGPoint curveStart =  CGPointMake(0,bounceView.center.y);
    CGPoint curveEnd =  CGPointMake(self.jellyDragView.bounds.size.width,bounceView.center.y);
    
    
    [bPath moveToPoint:curveStart];
    [bPath addQuadCurveToPoint:curveEnd controlPoint:dragView.center];
    [bPath addLineToPoint:CGPointMake(width,height)];
    [bPath addLineToPoint:CGPointMake(0,height)];
    [bPath addLineToPoint:curveStart];
    return bPath;
}

-(IBAction)handlePanGesture:(UIPanGestureRecognizer *)sender
{
    // normalise the translation between the top and bottom extents, clamp to 0 - 1
    CGPoint translate = [sender translationInView:self.jellyDragView];
    CGFloat range = self.jellyDragView.bounds.size.height;
    
    // calculate the ypos, and normalise to the range
    CGFloat ypos = (panStartPoint.y+translate.y) / range;
    value = MAX(0,MIN(ypos,1));
    dragView.center = CGPointMake(self.jellyDragView.bounds.size.width/2,value*self.jellyDragView.bounds.size.height);
    attachBehaviour.anchorPoint = dragView.center;
}

@end
