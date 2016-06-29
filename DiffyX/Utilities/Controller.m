/*
Diffy Doolittle X -- A File and Directory Comparison Utility.
Copyright (C) 2002  Gregory S. Combs

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*/

#import "Controller.h"
#import "Comparer.h"

@implementation Controller

- (instancetype)init
{
    self = [super init];
    NSMutableDictionary * defaultPrefs = [NSMutableDictionary dictionary];

    [defaultPrefs setObject:@"1" forKey:@"Compare Resources"];
    [defaultPrefs setObject:@"0" forKey:@"Delete Identical"];
    [defaultPrefs setObject:@"1" forKey:@"Report Different"];
    [defaultPrefs setObject:@"1" forKey:@"Report Identical"];
    [defaultPrefs setObject:@"1" forKey:@"Report Missing"];
    [defaultPrefs setObject:@"" forKey:@"New Path"];
    [defaultPrefs setObject:@"" forKey:@"Old Path"];

    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs registerDefaults:defaultPrefs];
    [prefs synchronize];

    return self;
}

- (void)dealloc
{
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];

    self.compResources.intValue = (int)[prefs integerForKey:@"Compare Resources"];
    self.delIdentical.intValue = (int)[prefs integerForKey:@"Delete Identical"];
    self.repDifferent.intValue = (int)[prefs integerForKey:@"Report Different"];
    self.repIdentical.intValue = (int)[prefs integerForKey:@"Report Identical"];
    self.repMissing.intValue = (int)[prefs integerForKey:@"Report Missing"];
    self.fieldNewPath.stringValue = [prefs stringForKey:@"New Path"];
    self.oldPath.stringValue = [prefs stringForKey:@"Old Path"];
}

- (IBAction)prefsChanged:(id)sender
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];

    if (sender == self.compResources) {
        [prefs setInteger:[self.compResources intValue] forKey:@"Compare Resources"];
    } else if (sender == self.delIdentical) {
        [prefs setInteger:[self.delIdentical intValue] forKey:@"Delete Identical"];
    } else if (sender == self.repDifferent) {
        [prefs setInteger:[self.repDifferent intValue] forKey:@"Report Different"];
    } else if (sender == self.repIdentical) {
        [prefs setInteger:[self.repIdentical intValue] forKey:@"Report Identical"];
    } else if (sender == self.repMissing) {
        [prefs setInteger:[self.repMissing intValue] forKey:@"Report Missing"];
    } else if (sender == self.fieldNewPath) {
        [prefs setObject:[self.fieldNewPath stringValue] forKey:@"New Path"];
    } else if (sender == self.oldPath) {
        [prefs setObject:[self.oldPath stringValue] forKey:@"Old Path"];
    }
    [prefs synchronize];
}

- (IBAction)compare:(id)sender
{
    [self forcePrefsUpdate];
    [self.comparer comparePaths];
}

- (IBAction)newBrowse:(id)sender
{
    NSInteger result = 0;
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
        [oPanel setAllowsMultipleSelection:NO];
        [oPanel setCanChooseDirectories:YES];
        [oPanel setCanChooseFiles:YES];
        [oPanel setResolvesAliases:YES];
        result = [oPanel runModalForDirectory:NSHomeDirectory()
                                         file:nil types:nil];
        if (result == NSOKButton) {
            NSString *aFile = [oPanel filename];
            [self.fieldNewPath setStringValue:aFile];

            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            [prefs setObject:[self.fieldNewPath stringValue] forKey:@"New Path"];
            [prefs synchronize];
        }
}

- (IBAction)oldBrowse:(id)sender
{
    NSInteger result = 0;
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setCanChooseDirectories:YES];
    [oPanel setCanChooseFiles:YES];
    [oPanel setResolvesAliases:YES];
    result = [oPanel runModalForDirectory:NSHomeDirectory()
                                     file:nil types:nil];
    if (result == NSOKButton) {
        NSString *aFile = [oPanel filename];
        [self.oldPath setStringValue:aFile];

        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        [prefs setObject:[self.oldPath stringValue] forKey:@"Old Path"];
        [prefs synchronize];
    }
}

- (void)forcePrefsUpdate
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];

    [prefs setInteger:[self.compResources integerValue] forKey:@"Compare Resources"];
    [prefs setInteger:[self.delIdentical integerValue] forKey:@"Delete Identical"];
    [prefs setInteger:[self.repDifferent integerValue] forKey:@"Report Different"];
    [prefs setInteger:[self.repIdentical integerValue] forKey:@"Report Identical"];
    [prefs setInteger:[self.repMissing integerValue] forKey:@"Report Missing"];
    [prefs setObject:[self.fieldNewPath stringValue] forKey:@"New Path"];
    [prefs setObject:[self.oldPath stringValue] forKey:@"Old Path"];

    [prefs synchronize];
}

@end
