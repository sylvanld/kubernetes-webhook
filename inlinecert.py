"""
Small utilities that convert a .pem file (~ .crt, .key...) into a one-liner certificate.
"""
import sys
import argparse


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument('path', help='Path to the certificate that should be inlined.')

    return parser.parse_args()


def inline_certificate():
    args = parse_args()

    try:
        # open certificate and remove eventually existing windows-style carriage returns
        content  = open(args.path).read().replace('\r', '')
        # extract only payload rows
        rows = [row for row in content.split('\n') if len(row)>0 and not row.startswith('-----')]
        # join payload row in a single very-long row
        data = ''.join(rows)
        # output certificate to stdout
        print(data)
    except FileNotFoundError as e:
        print(str(e), file=sys.stderr)
        exit(0)


if __name__ == '__main__':
    inline_certificate()
