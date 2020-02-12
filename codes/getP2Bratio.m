function p2bRatio = getP2Bratio(shortSubjectID)

% Hard-coded variable
pathOfAIF='/Users/lalithsimac/Documents/Input functions/Arterial input functions';% arterial input function
pathOfBIF='/Users/lalithsimac/Documents/Input functions/Blood input functions'; % whole blood input function

volunteerID=shortSubjectID;
cd(pathOfAIF);
AIFtable=dir([volunteerID,'*.txt']);
r=readtable(AIFtable.name);

cd(pathOfBIF);
BIFtable=dir([volunteerID,'*.txt'])
q=readtable(BIFtable.name);
p2bRatio=r.value_kBq_cc_./q.whole_blood_kBq_cc_; %plasma/wholeblood ratio
p2bRatio(isnan(p2bRatio))=[];
p2bRatio=mean(p2bRatio);
end
