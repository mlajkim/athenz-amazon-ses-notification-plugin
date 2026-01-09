package com.mlajkim.athenz;

import com.yahoo.athenz.auth.PrivateKeyStore;
import com.yahoo.athenz.common.server.notification.*;

import jakarta.mail.*;
import jakarta.mail.internet.*;
import java.util.*;

public class AwsSesPlugin implements NotificationServiceFactory {
    @Override
    public NotificationService create(PrivateKeyStore privateKeyStore) {
        System.out.println(">>> [AWS-SES] Factory create() called! Creating SesService...");

        return new SesService();
    }
}

class SesService implements NotificationService {

    private static final String EMAIL_BODY_TEMPLATE = "Dear Athenz User,\n\n"
            + "This is an automated notification from the Athenz system.\n\n"
            + "Details:\n"
            + "%s\n\n"
            + "Please review this information and take appropriate action.\n\n"
            + "Thank you,\n"
            + "The Athenz Team\n\n"
            + "(This is an auto-generated email, please do not reply.)";

    private static final String SMTP_USER = System.getenv("AWS_SES_USER");
    private static final String SMTP_PASS = System.getenv("AWS_SES_PASS");
    private static final String SMTP_HOST = "email-smtp.ap-northeast-1.amazonaws.com";
    private static final int SMTP_PORT = 587;
    private static final String SENDER = "jkim67cloud@gmail.com";

    @Override
    public boolean notify(Notification notification) {
        System.out.println(">>> [AWS-SES] Start sending email (mlajkim plugin)...");

        if (SMTP_USER == null || SMTP_PASS == null) {
            System.out.println(">>> [AWS-SES] Error: Env Vars missing!");
            return false;
        }

        Properties props = new Properties();
        props.put("mail.smtp.host", SMTP_HOST);
        props.put("mail.transport.protocol", "smtp");
        props.put("mail.smtp.port", SMTP_PORT);
        props.put("mail.smtp.starttls.enable", "true");
        props.put("mail.smtp.auth", "true");

        Session session = Session.getInstance(props, new jakarta.mail.Authenticator() {
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(SMTP_USER, SMTP_PASS);
            }
        });


        try {
            Set<String> recipients = notification.getRecipients();
            Set<String> sentEmails = new HashSet<>();

            if (recipients == null || recipients.isEmpty()) {
                System.out.println(">>> [AWS-SES] No recipients found, aborting email send.");
                return false;
            }

            System.out.println(">>> [AWS-SES] Attempting to send email to recipients: " + String.join(", ", recipients));

            String subject = "Athenz Notification";
            String body = "This is an automated notification from Athenz.";

            Map<String, String> details = notification.getDetails();
            if (details != null) {
                subject = details.getOrDefault("subject", subject);
                body = details.getOrDefault("body", body);
            }

            String emailBody = String.format(EMAIL_BODY_TEMPLATE, body);

            for (String recipient : recipients) {
                String targetEmail = recipient + "@gmail.com";

                try { // allow per-recipient failure handling
                    if (recipient.startsWith("user.")) {
                        targetEmail = recipient.substring(5) + "@gmail.com";
                    }

                    MimeMessage msg = new MimeMessage(session);
                    msg.setFrom(new InternetAddress(SENDER, "Athenz Admin"));
                    msg.setRecipient(Message.RecipientType.TO, new InternetAddress(targetEmail));

                    msg.setSubject(subject);
                    msg.setText(emailBody, "UTF-8");

                    Transport.send(msg);
                    System.out.println(">>> [AWS-SES] Sent to: " + recipient);

                    sentEmails.add(targetEmail);
                } catch (Exception e){
                    System.out.println(">>> [AWS-SES] SKIP: Failed to send to " + targetEmail + " (" + e.getMessage() + ")");
                }
            }

            // log:
            if (sentEmails.isEmpty()) {
                System.out.println(">>> [AWS-SES] No emails were sent successfully.");
                return false; // no successful sends
            } else {
                System.out.println(">>> [AWS-SES] Email sent to: " + String.join(", ", sentEmails));
            }

            return true; // successful send

        } catch (Exception e) {
            System.out.println(">>> [AWS-SES] Error during email send:" + e.getMessage());
            e.printStackTrace();
            return false; // any exception results in failure
        }
    }
}